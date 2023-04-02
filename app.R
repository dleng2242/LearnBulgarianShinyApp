
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
    h3(title),
    
    hr(),
    valueBoxOutput(outputId = NS(id, "box_question_num")),
    valueBoxOutput(outputId = NS(id, "box_score")),
    valueBoxOutput(outputId = NS(id, "box_time")),
    hr(),
    
    fluidRow(
      div(
        textOutput(outputId = NS(id, "question_question")),
        textOutput(outputId = NS(id, "question_result")),
        br(),
        textInput(inputId = NS(id, "question_answer"), label = "Answer: "),
        br(),
        column(
          width = 6,
          br(),
          actionButton(inputId = NS(id, "question_submit"), label = "Submit"),
          actionButton(inputId = NS(id, "question_next"), label = "Next"),
          actionButton(inputId = NS(id, "question_stop"), label = "Stop"),
          actionButton(inputId = NS(id, "question_go_reset"), label = "Reset")
        ),
        style = "margin:10px"
      )
    )
  )
}

questionServer <- function(id, df_questions) {
  stopifnot(!is.reactive(df_questions))
  
  moduleServer(id, function(input, output, session) {
    
    df_questions
    
    question_idx <- reactiveVal(value = 1)
    question_answered <- reactiveVal(value = FALSE)
    
    questions_correct <- reactiveVal(value = 0)
    questions_answered <- reactive({question_idx() - 1})
    questions_total <- reactive({nrow(df_questions)})
    
    game_timer_time <- reactiveVal(value = 0)
    game_timer_active <- reactiveVal(value = TRUE)
    
    
    observeEvent(input$question_go_reset, {
      question_idx(1)
      questions_correct(0)
      game_timer_time(0)
      game_timer_active(TRUE)
      shinyjs::enable("question_submit")
      shinyjs::enable("question_next")
    })
    
    observeEvent(input$question_stop, {
      game_timer_active(FALSE)
      shinyjs::disable("question_submit")
      shinyjs::disable("question_next")
    })
    
    observeEvent(input$question_next, {
      question_idx(isolate(question_idx() + 1)) 
      question_answered(FALSE)
      # clear previous answer
      updateTextInput(inputId = "question_answer", value = "")
    })
    
    observe({
      # every 1000 ms update the game_timer_time if active
      invalidateLater(1000, session)
      isolate({
        if (game_timer_active()) {
          game_timer_time(game_timer_time() + 1)
        }
      })
    })
    
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
    
    
    question_outcome <- eventReactive(input$question_submit, {
      real_answer <-  df_questions$answers[question_idx()]
      
      if (is.null(input$question_answer)){return(-1)}
      
      question_answer <- tolower(input$question_answer)
      if (!(question_answer == real_answer)){
        if (!question_answered()) {
          question_answered(TRUE)
        }
        txt <- glue("Not quite! The correct answer is {real_answer}.")
        return(txt)
      }
      if (question_answer == real_answer){
        if (!question_answered()) {
          questions_correct(isolate(questions_correct() + 1))
          question_answered(TRUE)
        }
        txt <- glue("Great! The correct answer is {real_answer}.")
        return(txt)
      }
    })
    
    output$question_question <- renderText({
      df_questions$questions[question_idx()]
    })
    
    output$question_result <- renderText({
      question_outcome()
    })
    
  })
}

title = "Learn Bulgarian"
ui <- navbarPage(
  title = div(
    img(
      src="Flag_of_Bulgaria.png", 
      height = 20,
    ),
    title
  ), 
  header = titlePanel(
    title = div(
      img(
        src="Flag_of_Bulgaria.png", 
        height = 40,
        style = "margin:10px 10px"
      ),
      title
    )
  ),
  footer = div(
    "This app was created by Duncan Leng (March 2023).",
    style = "margin:10px 10px"
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
