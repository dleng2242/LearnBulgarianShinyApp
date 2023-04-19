#' 02_vocab UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#' @param title Section title.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_02_vocab_ui <- function(id, title){
  ns <- NS(id)
  tagList(
    fluidRow(
      column(width = 3),
      column(
        width = 6, align="center",
        h3(title),
        hr(),
        tableOutput(outputId = NS(id, "vocab_table")),
        br()
      ) %>% tagAppendAttributes(class="main_col_class"),
      column(width = 3)
    )
  )
}

#' 02_vocab Server Functions
#'
#' @param df_vocab DataFrame of vocab to display.Expects columns called
#'     "bulgarian", "english", and "notes".
#'
#' @noRd
mod_02_vocab_server <- function(id, df_vocab){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
    logger::log_info(glue::glue("Rendering vocabServer {id}"))
    output$vocab_table <- renderTable({
      logger::log_info(glue::glue("Rendering vocabServer {id} vocab_table"))
      df_vocab %>% dplyr::rename(
        Bulgarian = "bulgarian",
        English = "english",
        Notes = "notes"
      ) %>%
      dplyr::mutate(Notes = dplyr::if_else(is.na(Notes), "", Notes))
    })
  })
}

## To be copied in the UI
# mod_02_vocab_ui("02_vocab_1")

## To be copied in the server
# mod_02_vocab_server("02_vocab_1")
