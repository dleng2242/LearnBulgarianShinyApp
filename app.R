
library(glue)
library(shiny)
library(shinydashboard)
library(shinyjs)
library(tidyverse)
library(hms)



startUI <- function(id, title) {
  tagList(
    fluidRow(
      column(width = 2),
      column(
        width = 8,
        fluidRow(
          #style = "padding: 0px 0px 0px 20px;",
          column(
            width = 3,
            div(
              img(
                src="Flag_of_Bulgaria.png", 
                height = 60
              ),
              style = "padding: 20px 0px 0px 20px;"
            )
          ),
          column(
            width = 6,
            align = "center",
            titlePanel(title = title),
            style = "padding: 15px 0px 0px 0px;"
          ),
          column(width = 3)
        ),
        
        hr(),
        br(),
        p("Welcome to my Learn Bulgarian App."),
        br(),
        p("This app was developed to help me learn Bulgarian (and R 
          Shiny). It is fairly simple with only two main components: tables 
          of vocab and a quiz section to test your knowledge. 
          Different topics can be found in the Vocab and Quiz menus above."),
        br(),
        p("Currently there are only a few topics, but I will add more in future!"),
        br(),
        p("Enjoy studying!"),
        hr(),
        br()
      ) %>% tagAppendAttributes(class="main_col_class"),
      column(width = 2)
    )
  )
}

vocabUI <- function(id, title) {
  tagList(
    fluidRow(
      column(width = 2),
      column(
        width = 8, align="center",
        h3(title),
        hr(),
        tableOutput(outputId = NS(id, "vocab_table")),
        hr(),
        br()
      ) %>% tagAppendAttributes(class="main_col_class"),
      column(width = 2)
    )
  )
}

questionUI <- function(id, title, description) {
  tagList(
    
    fluidRow(
      column(width = 2),
      column(
        width = 8, align="center",
        h3(title),
        
        hr(),
        valueBoxOutput(outputId = NS(id, "box_question_num")),
        valueBoxOutput(outputId = NS(id, "box_score")),
        valueBoxOutput(outputId = NS(id, "box_time")),
        hr(),
        fluidRow(
          div(
            br(),
            p(description),
            textOutput(outputId = NS(id, "question_question")),
            br(),
            textOutput(outputId = NS(id, "question_result")),
            br(),
            textInput(inputId = NS(id, "question_answer"), label = "Answer: "),
            br(),
            column(
              width = 12, align="center",
              br(),
              actionButton(inputId = NS(id, "question_submit"), label = "Submit"),
              actionButton(inputId = NS(id, "question_next"), label = "Next"),
              actionButton(inputId = NS(id, "question_stop_start"), label = "Start"),
              actionButton(inputId = NS(id, "question_reset"), label = "Reset"),
              br(),
              hr()
            ),
            br(),
            hr(),
            br(),
            style = "padding: 15px 0px 20px 0px;"
          )
        )
      ) %>% tagAppendAttributes(class="main_col_class"),
      column(width = 2)
    )
  )
}

vocabServer <- function(id, df_vocab) {
  moduleServer(id, function(input, output, session) {
    output$vocab_table <- renderTable({
      df_vocab %>% rename(
        Bulgarian = "bulgarian",
        English = "english",
        Notes = "notes"
        ) %>% 
        mutate(Notes = if_else(is.na(Notes), "", Notes))
    })
  })
}

questionServer <- function(id, df_questions) {
  stopifnot(!is.reactive(df_questions))
  
  moduleServer(id, function(input, output, session) {
    
    # randomly permute rows - this only 
    # df_questions assumes three columns:
    #   bulgarian, english, and notes
    # all values reactive to sync when re-shuffles in reset
    df_questions_rv <- reactiveVal({
      #slice_sample(df_questions, prop = 1L)
      df_questions
    })
    questions <- reactive({df_questions_rv()$bulgarian})
    answers <- reactive({df_questions_rv()$english})
    notes <- reactive({df_questions_rv()$notes})

    
    # four app states - start in pre-quiz
    state_pre_quiz <- reactiveVal(value = TRUE)
    state_question_live <- reactiveVal(value = FALSE)
    state_question_answered <- reactiveVal(value = FALSE)
    state_post_quiz <- reactiveVal(value = FALSE)
    
    # values to record question state
    question_idx <- reactiveVal(value = 0)
    questions_correct <- reactiveVal(value = 0)
    questions_answered <- reactiveVal(value = 0)
    questions_total <- reactive({nrow(df_questions)})
    question_response <- reactiveVal(value = " ")
    
    # timer value
    game_timer_time <- reactiveVal(value = 0)
    
    # game starts with buttons inactive
    shinyjs::disable("question_submit")
    shinyjs::disable("question_next")
    shinyjs::disable("question_reset")
    # only start is enabled
    shinyjs::enable("question_stop_start")
    
    
    # Stop/Start
    observeEvent(input$question_stop_start, {
      if (state_pre_quiz()) {
        updateActionButton(
          inputId = "question_stop_start",
          label = "Stop"
          )
        
        # randomly permute rows
        #   re-shuffles each time the game starts 
        df_questions_rv(slice_sample(df_questions_rv(), prop = 1L))
        
        # update question index to first question
        question_idx(isolate(question_idx() + 1))
        # update states
        state_pre_quiz(FALSE)
        state_question_live(TRUE)
        shinyjs::enable("question_submit")
        shinyjs::disable("question_reset")
      } else if (state_question_live() || state_question_answered()) {
        updateActionButton(
          inputId = "question_stop_start",
          label = "Start"
        )
        # clear any text in input
        updateTextInput(inputId = "question_answer", value = "")
        # update states
        state_question_live(FALSE)
        state_question_answered(FALSE)
        state_post_quiz(TRUE)
        # disable button when in post-quiz state - need to reset first
        shinyjs::disable("question_stop_start")
        shinyjs::disable("question_submit")
        shinyjs::disable("question_next")
        # enable reset button - only time this can be accessed
        shinyjs::enable("question_reset")
      } else if (state_post_quiz()) {
        warning("Stop/Start button pressed while in post-quiz state")
      }
    })
    
    output$question_question <- renderText({
      if (state_pre_quiz()) {
        "Click Start to begin."
      } else if (state_question_live()){
        glue("{questions()[question_idx()]}")
      } else if (state_question_answered()) {
        glue("{questions()[question_idx()]}")
      } else if (state_post_quiz()) {
        "Quiz Finished! Click Reset to try again."
      }
    })
    
    
    observeEvent(input$question_submit, {
      if (state_pre_quiz()) {
        warning("Submit button pressed while in pre-quiz state")
      } else if (state_question_live()){

        # Move state
        state_question_live(FALSE)
        state_question_answered(TRUE)
        shinyjs::disable("question_submit")
        shinyjs::enable("question_next")
        
        # Evaluate correct response
        real_answer <-  answers()[question_idx()]
        
        # update questions answered
        questions_answered(isolate(questions_answered() + 1))
        
        if (is.null(input$question_answer)){return(-1)}
        
        question_answer <- tolower(input$question_answer)
        if (!(tolower(question_answer) == tolower(real_answer))){
          txt <- glue("\U274c Not quite! The correct answer is {real_answer}.")
          question_response(txt)
        }
        if (tolower(question_answer) == tolower(real_answer)){
          # update questions correct
          questions_correct(isolate(questions_correct() + 1))
          txt <- glue("\U2705 Great! The correct answer is {real_answer}.")
          question_response(txt)
        }

      } else if (state_question_answered()) {
        warning("Submit button pressed while in question answered state")
      } else if (state_post_quiz()) {
        warning("Submit button pressed while in post-quiz state")
      }
    })
    
    
    # question result
    output$question_result <- renderText({
      if (state_pre_quiz()) {
        " "
      } else if (state_question_live()){
        " "
      } else if (state_question_answered()) {
        question_response()
      } else if (state_post_quiz()) {
        glue("Great - Your scored {questions_correct()}/{questions_answered()}")
      }
      
    })
    
    
    # next button 
    observeEvent(input$question_next, {
      if (state_pre_quiz()) {
        warning("Next button pressed while in pre-quiz state")
      } else if (state_question_live()){
        warning("Next button pressed while in live question state")
      } else if (state_question_answered()) {
        # clear previous answer from answer input
        updateTextInput(inputId = "question_answer", value = "")
        if (question_idx() >= questions_total()){
          updateActionButton(
            inputId = "question_stop_start",
            label = "Start"
          )
          state_question_live(FALSE)
          state_question_answered(FALSE)
          state_post_quiz(TRUE)
          # disable button when in post-quiz state - need to reset first
          shinyjs::disable("question_stop_start")
          shinyjs::disable("question_submit")
          shinyjs::disable("question_next")
          # enable reset button - only time this can be accessed
          shinyjs::enable("question_reset")
          
        } else {
          # change question index before we change state
          question_idx(isolate(question_idx() + 1)) 
          state_question_answered(FALSE)
          state_question_live(TRUE)
          shinyjs::disable("question_next")
          shinyjs::enable("question_submit")
        }
      } else if (state_post_quiz()) {
        warning("Next button pressed while in post-quiz state")
      }
    })
    
    # reset button
    observeEvent(input$question_reset, {
      
      if (state_pre_quiz()) {
        warning("Reset button pressed while in pre-quiz state")
      } else if (state_question_live()){
        warning("Reset button pressed while in live question state")
      } else if (state_question_answered()) {
        warning("Reset button pressed while in question answered state")
      } else if (state_post_quiz()) {
        # reset all values
        question_idx(0)
        questions_correct(0)
        questions_answered(0)
        game_timer_time(0)
        state_post_quiz(FALSE)
        state_pre_quiz(TRUE)
        shinyjs::enable("question_stop_start")
        shinyjs::disable("question_reset")
      }
    })
    
    # timer
    observe({
      # every 1000 ms update the game_timer_time if active
      invalidateLater(1000, session)
      isolate({
        if (state_question_live() || state_question_answered()) {
          game_timer_time(game_timer_time() + 1)
        }
      })
    })
    
    
    # value boxes
    output$box_question_num <- renderValueBox({
      valueBox(
        value = glue("{question_idx()}/{questions_total()}"),
        subtitle = "Question",
        #icon = icon("question"),
        width = 4
      )
    })
    output$box_score <- renderValueBox({
      valueBox(
        value = glue("{questions_correct()}/{questions_answered()}"),
        subtitle = "Score",
        #icon = icon("credit-card"),
        width = 4
      )
    })
    output$box_time <- renderValueBox({
      # whenever game_timer_time() changes, this also updates
      time <- hms(game_timer_time())
      valueBox(
        value = glue("{time}"),
        subtitle = "Time",
        width = 4
      )
    })
    
    
  })
}

title = "Learn Bulgarian"
ui <- navbarPage(
  title = div(
    img(
      src="Flag_of_Bulgaria.png", 
      height = 20
    ),
    title
  ), 
  footer = div(
    br(),
    hr(),
    br(),
    "Created by Duncan Leng (March 2023).",
    style = "margin:10px 10px",
    align = "right"
  ),
  
  tags$head(
    tags$link(
      rel = "stylesheet", 
      type = "text/css", 
      href = "style.css"
      )
    ),
  useShinyjs(),
  
  tabPanel("Start", startUI("start_page", title)),
  
  navbarMenu(
    "Vocab",
    tabPanel(
      "Cyrillic Alphabet",
      vocabUI("vocab_cyrillic", title = "The Cyrillic Alphabet")
    ),
    tabPanel(
      "Numbers",
      vocabUI("vocab_numbers", title = "Numbers")
    ),
    tabPanel(
      "Food",
      vocabUI("vocab_food", title = "Common Food")
    ),
    tabPanel(
      "Drinks",
      vocabUI("vocab_drinks", title = "Bulgarian Drinks")
    ),
    tabPanel(
      "Animals",
      vocabUI("vocab_animals", title = "Bulgarian Animals")
    ),
    tabPanel(
      "Question Words",
      vocabUI("vocab_question_words", title = "Question Words")
    ),
  ), 
  
  navbarMenu(
    "Quiz",
    tabPanel(
      "Cyrillic Alphabet",
      questionUI(
        "quiz_cyrillic", 
        title = "Cyrillic Alphabet Quiz",
        description = "Enter the transliteration for the Cyrillic symbol given."
        )
    ),
    tabPanel(
      "Numbers",
      questionUI(
        "quiz_numbers", 
        title = "Numbers Quiz",
        description = "Translate the number in letter form."
        )
    ),
    tabPanel(
      "Food",
      questionUI(
        "quiz_food", 
        title = "Food Quiz",
        description = "Translate the food item."
      )
    ),
    tabPanel(
      "Drinks",
      questionUI(
        "quiz_drinks", 
        title = "Drinks Quiz",
        description = "Translate the drink."
      )
    ),
    tabPanel(
      "Animals",
      questionUI(
        "quiz_animals", 
        title = "Animals Quiz",
        description = "Translate the name of the animal"
        )
    ),
    tabPanel(
      "Question Words",
      questionUI(
        "quiz_question_words", 
        title = "Question Words Quiz",
        description = "Translate the question."
      )
    )
  )
)

server <- function(input, output, session) {
  df_cyrillic <- read_csv("./data/bulgarian_cyrillic_alphabet.csv")
  questionServer("quiz_cyrillic", df_questions = df_cyrillic)
  vocabServer("vocab_cyrillic", df_vocab = df_cyrillic)
  
  df_numbers <- read_csv("./data/bulgarian_numbers.csv")
  questionServer("quiz_numbers", df_questions = df_numbers)
  vocabServer("vocab_numbers", df_vocab = df_numbers)
  
  df_food <- read_csv("./data/bulgarian_food.csv")
  questionServer("quiz_food", df_questions = df_food)
  vocabServer("vocab_food", df_vocab = df_food)
  
  df_drinks <- read_csv("./data/bulgarian_drinks.csv")
  questionServer("quiz_drinks", df_questions = df_drinks)
  vocabServer("vocab_drinks", df_vocab = df_drinks)
  
  df_animals <- read_csv("./data/bulgarian_animals.csv")
  questionServer("quiz_animals", df_questions = df_animals)
  vocabServer("vocab_animals", df_vocab = df_animals)
  
  df_question_words <- read_csv("./data/bulgarian_questions.csv")
  questionServer("quiz_question_words", df_questions = df_question_words)
  vocabServer("vocab_question_words", df_vocab = df_question_words)
}


shinyApp(ui = ui, server = server)
