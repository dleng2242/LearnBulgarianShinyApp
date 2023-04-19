#' 01_start UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#' @param title Section title.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_01_start_ui <- function(id, title){
  ns <- NS(id)
  tagList(
    fluidRow(
      column(width = 3),
      column(
        width = 6,
        class="main_col_class",
        fluidRow(
          column(
            width = 3,
            div(
              img(
                src="www/Flag_of_Bulgaria.png",
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
      ),
      column(width = 3)
    )
  )
}

#' 01_start Server Functions
#'
#' @noRd
mod_01_start_server <- function(id){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

  })
}

## To be copied in the UI
# mod_01_start_ui("01_start_1")

## To be copied in the server
# mod_01_start_server("01_start_1")
