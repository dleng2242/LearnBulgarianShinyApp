
#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    navbarPage(
      title = div(
        img(
          src="www/Flag_of_Bulgaria.png",
          height = 20,
          style = "margin:0px 5px 5px 0px",
        ),
        "Learn Bulgarian"
      ),
      footer = div(
        br(),
        hr(),
        "Created by Duncan Leng (March 2023).",
        style = "margin:10px 10px",
        align = "right"
      ),

      tabPanel(
        "Start",
        mod_01_start_ui("start_page", title = "Learn Bulgarian")
      ),

      navbarMenu(
        "Vocab",
        tabPanel(
          "Cyrillic Alphabet",
          mod_02_vocab_ui("vocab_cyrillic", title = "The Cyrillic Alphabet")
        ),
        tabPanel(
          "Numbers",
          mod_02_vocab_ui("vocab_numbers", title = "Numbers")
        ),
        tabPanel(
          "Food",
          mod_02_vocab_ui("vocab_food", title = "Common Food")
        ),
        tabPanel(
          "Drinks",
          mod_02_vocab_ui("vocab_drinks", title = "Bulgarian Drinks")
        ),
        tabPanel(
          "Animals",
          mod_02_vocab_ui("vocab_animals", title = "Bulgarian Animals")
        ),
        tabPanel(
          "Question Words",
          mod_02_vocab_ui("vocab_question_words", title = "Question Words")
        ),
      ),

      navbarMenu(
        "Quiz",
        tabPanel(
          "Cyrillic Alphabet",
          mod_03_question_ui(
            "quiz_cyrillic",
            title = "Cyrillic Alphabet Quiz",
            description = "Enter the transliteration for the Cyrillic symbol given."
          )
        ),
        tabPanel(
          "Numbers",
          mod_03_question_ui(
            "quiz_numbers",
            title = "Numbers Quiz",
            description = "Translate the number in letter form."
          )
        ),
        tabPanel(
          "Food",
          mod_03_question_ui(
            "quiz_food",
            title = "Food Quiz",
            description = "Translate the food item."
          )
        ),
        tabPanel(
          "Drinks",
          mod_03_question_ui(
            "quiz_drinks",
            title = "Drinks Quiz",
            description = "Translate the drink."
          )
        ),
        tabPanel(
          "Animals",
          mod_03_question_ui(
            "quiz_animals",
            title = "Animals Quiz",
            description = "Translate the name of the animal"
          )
        ),
        tabPanel(
          "Question Words",
          mod_03_question_ui(
            "quiz_question_words",
            title = "Question Words Quiz",
            description = "Translate the question."
          )
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "LearnBulgarianShinyAppGolem"
    ),
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
    shinyjs::useShinyjs()
  )
}
