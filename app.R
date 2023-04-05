
library(glue)
library(shiny)
library(shinydashboard)
library(shinyjs)
library(tidyverse)
library(hms)



df <- read_csv("./data/bulgarian_letters_dataset.csv")

# Questions made from data 
questions <- paste0(
  "What is the transliteration for '",
  df$bg_upper, "/", df$bg_lower, "' ?"
)
# all answers lowercase
answers <- df$transliteration_lower
stopifnot(length(questions) == length(answers))

# throw into df to be used later
df_cyrillic_questions <- data.frame(questions = questions, answers = answers)



questionUI <- function(id, title) {
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
              actionButton(inputId = NS(id, "question_reset"), label = "Reset")
            ),
            br(),
            hr(),
            style = "margin:10px"
          )
        )
      ),
      column(width = 2)
    )
  )
}

questionServer <- function(id, df_questions) {
  stopifnot(!is.reactive(df_questions))
  
  moduleServer(id, function(input, output, session) {
    
    # randomly permute rows
    df_questions = slice_sample(df_questions, prop = 1L)
    
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
        df_questions$questions[question_idx()]
      } else if (state_question_answered()) {
        df_questions$questions[question_idx()]
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
        real_answer <-  df_questions$answers[question_idx()]
        
        # update questions answered
        questions_answered(isolate(questions_answered() + 1))
        
        if (is.null(input$question_answer)){return(-1)}
        
        question_answer <- tolower(input$question_answer)
        if (!(question_answer == real_answer)){
          txt <- glue("\U274c Not quite! The correct answer is {real_answer}.")
          question_response(txt)
        }
        if (question_answer == real_answer){
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
    "This app was created by Duncan Leng (March 2023).",
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
  
  tabPanel("Start"),
  
  navbarMenu(
    "Learn",
    tabPanel(
      "Cyrillic Alphabet"
    ),
    tabPanel(
      "Animals"
    )
  ), 
  
  navbarMenu(
    "Quiz",
    tabPanel(
      "Cyrillic Alphabet",
      questionUI("Question_1", title = "Cyrillic Alphabet Quiz")
    ),
    tabPanel(
      "Animals",
      questionUI("Question_2", title = "Bulgarian Animals Quiz")
    )
  )
)

server <- function(input, output, session) {
  questionServer("Question_1", df_questions = df_cyrillic_questions)
  questionServer("Question_2", df_questions = df_cyrillic_questions)
}


shinyApp(ui = ui, server = server)
