#' 03_question UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#' @param title Quiz title.
#' @param description Short quiz description.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_03_question_ui <- function(id, title, description){
  ns <- NS(id)
  tagList(
    fluidRow(
      column(width = 3),
      column(
        width = 6, align="center",
        h3(title),
        hr(),
        shinydashboard::valueBoxOutput(outputId = NS(id, "box_question_num")),
        shinydashboard::valueBoxOutput(outputId = NS(id, "box_score")),
        shinydashboard::valueBoxOutput(outputId = NS(id, "box_time")),
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
      column(width = 3)
    )
  )
}

#' 03_question Server Functions
#'
#' @param df_questions DataFrame of questions. Expects columns called
#'     "bulgarian", "english", and "notes".
#'
#' @noRd
mod_03_question_server <- function(id, df_questions){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    logger::log_info(glue::glue("Rendering questionServer {id}"))

    # randomly permute rows - this only
    # df_questions assumes three columns:
    #   bulgarian, english, and notes
    # all values reactive to sync when re-shuffles in reset
    df_questions_rv <- reactiveVal({
      df_questions
    })
    questions <- reactive({
      logger::log_info(glue::glue("Rendering questionServer {id} questions"))
      df_questions_rv()$bulgarian
    })
    answers <- reactive({
      logger::log_info(glue::glue("Rendering questionServer {id} answers"))
      df_questions_rv()$english
    })
    notes <- reactive({
      logger::log_info(glue::glue("Rendering questionServer {id} notes"))
      df_questions_rv()$notes
    })


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
      logger::log_info(glue::glue("Observed questionServer {id} question_stop_start"))
      if (state_pre_quiz()) {
        updateActionButton(
          inputId = "question_stop_start",
          label = "Stop"
        )

        # randomly permute rows
        #   re-shuffles each time the game starts
        df_questions_rv(dplyr::slice_sample(df_questions_rv(), prop = 1L))

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
      logger::log_info(glue::glue("Rendering questionServer {id} question_question"))
      if (state_pre_quiz()) {
        "Click Start to begin."
      } else if (state_question_live()){
        glue::glue("{questions()[question_idx()]}")
      } else if (state_question_answered()) {
        glue::glue("{questions()[question_idx()]}")
      } else if (state_post_quiz()) {
        "Quiz Finished! Click Reset to try again."
      }
    })


    observeEvent(input$question_submit, {
      logger::log_info(glue::glue("Observed questionServer {id} question_submit"))
      if (state_pre_quiz()) {
        warning("Submit button pressed while in pre-quiz state")
      } else if (state_question_live()){

        # Move state
        state_question_live(FALSE)
        state_question_answered(TRUE)
        shinyjs::disable("question_submit")
        shinyjs::enable("question_next")

        # Evaluate correct response
        real_answer <- answers()[question_idx()]

        # update questions answered
        questions_answered(isolate(questions_answered() + 1))

        if (is.null(input$question_answer)){return(-1)}

        question_answer <- tolower(input$question_answer)
        if (!(tolower(question_answer) == tolower(real_answer))){
          txt <- glue::glue("\U274c Not quite! The correct answer is {real_answer}.")
          question_response(txt)
        }
        if (tolower(question_answer) == tolower(real_answer)){
          # update questions correct
          questions_correct(isolate(questions_correct() + 1))
          txt <- glue::glue("\U2705 Great! The correct answer is {real_answer}.")
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
      logger::log_info(glue::glue("Rendering questionServer {id} question_result"))
      if (state_pre_quiz()) {
        " "
      } else if (state_question_live()){
        " "
      } else if (state_question_answered()) {
        question_response()
      } else if (state_post_quiz()) {
        glue::glue("Great - Your scored {questions_correct()}/{questions_answered()}")
      }

    })


    # next button
    observeEvent(input$question_next, {
      logger::log_info(glue::glue("Observed questionServer {id} question_next"))
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
      logger::log_info(glue::glue("Observed questionServer {id} question_reset"))
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
    output$box_question_num <- shinydashboard::renderValueBox({
      logger::log_info(glue::glue("Rendering questionServer {id} box_question_num"))
      shinydashboard::valueBox(
        value = glue::glue("{question_idx()}/{questions_total()}"),
        subtitle = "Question",
        #icon = icon("question"),
        width = 4
      )
    })
    output$box_score <- shinydashboard::renderValueBox({
      logger::log_info(glue::glue("Rendering questionServer {id} box_score"))
      shinydashboard::valueBox(
        value = glue::glue("{questions_correct()}/{questions_answered()}"),
        subtitle = "Score",
        #icon = icon("credit-card"),
        width = 4
      )
    })
    output$box_time <- shinydashboard::renderValueBox({
      # do not log timer
      # logger::log_info(glue::glue("Rendering questionServer {id} box_time"))
      # whenever game_timer_time() changes, this also updates
      time <- hms::hms(game_timer_time())
      shinydashboard::valueBox(
        value = glue::glue("{time}"),
        subtitle = "Time",
        width = 4
      )
    })
  })
}

## To be copied in the UI
# mod_03_question_ui("03_question_1")

## To be copied in the server
# mod_03_question_server("03_question_1")
