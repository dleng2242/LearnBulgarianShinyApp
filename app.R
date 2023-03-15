
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
num_questions <- length(questions)

stopifnot(length(questions) == length(answers))



ui <- fluidPage(
  
  tags$head(
    tags$link(
      rel = "stylesheet", 
      type = "text/css", 
      href = "style.css"
      )
    ),
  useShinyjs(),
  
  fluidRow(
    column(width = 3),
    column(
      width = 6,
      
      titlePanel(
        title = div(
          img(
            src="Flag_of_Bulgaria.png", 
            height = 50,
            style = "margin:10px 10px"
            ),
          "The Learn Bulgarian Shiny App"
          ),
        windowTitle = "Learn Bulgarian"
        ),
      
      
      h3("Cyrillic Alphabet Quiz"),
      
      hr(),
      
      fluidRow(
        column(width = 3, valueBoxOutput(outputId = "box_question_num", width = 12)),
        column(width = 3, valueBoxOutput(outputId = "box_score", width = 12)),
        column(width = 3),
        column(width = 3, valueBoxOutput(outputId = "box_time", width = 12))
      ),
      
      hr(),
      
      fluidRow(
        div(
          textOutput(outputId = "question_question"),
          column(
            width = 6,
            textInput(inputId = "question_answer", label = "Answer: "),
            br(),
            actionButton(inputId = "question_submit", label = "Submit"),
            actionButton(inputId = "question_next", label = "Next"),
            actionButton(inputId = "question_stop", label = "Stop"),
            actionButton(inputId = "question_go_reset", label = "Reset")
          ),
          column(
            width = 6, 
            textOutput(outputId = "question_result")
          ),
          style = "margin:10px"
        )
      ),
      
      br(),
      hr(),
      br(),
      
      p("This app was created by Duncan Leng (March 2023).")
      
    ) %>% tagAppendAttributes(class="main_col_class"),
    column(width = 3)
  )
  
  
)

server <- function(input, output, session) {
  
  question_idx <- reactiveVal(value = 1)
  question_answered <- reactiveVal(value = FALSE)
  game_score <- reactiveVal(value = 0)
  
  game_timer_time <- reactiveVal(value = 0)
  game_timer_active <- reactiveVal(value = TRUE)
  
  
  observeEvent(input$question_go_reset, {
    question_idx(1)
    game_score(0)
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
      value = glue("{question_idx()}/30"),
      subtitle = "Question",
      #icon = icon("question"),
      width = 4
    )
  })
  output$box_score <- renderValueBox({
    valueBox(
      value = glue("{game_score()}/30"),
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
    real_answer <-  answers[question_idx()]
    if (is.null(input$question_answer)){return(-1)}
    
    question_answer <- tolower(input$question_answer)
    if (!(question_answer == real_answer)){
      if (!question_answered()) {
        question_answered(TRUE)
      }
      txt <- glue("Not quite! The correct answer is {answers[question_idx()]}.")
      return(txt)
      }
    if (question_answer == real_answer){
      if (!question_answered()) {
        game_score(isolate(game_score() + 1))
        question_answered(TRUE)
      }
      txt <- glue("Great! The correct answer is {answers[question_idx()]}.")
      return(txt)
      }
    })
  
  output$question_question <- renderText({
    questions[question_idx()]
    })
  
  output$question_result <- renderText({
    question_outcome()
    })
  
  
}


shinyApp(ui = ui, server = server)
