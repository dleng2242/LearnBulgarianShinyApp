#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @importFrom dplyr %>%
#'
#' @noRd
app_server <- function(input, output, session) {
  # all data from internal datastore - see data-raw for originals 
  
  mod_03_question_server("quiz_cyrillic", df_questions = df_cyrillic)
  mod_02_vocab_server("vocab_cyrillic", df_vocab = df_cyrillic)

  mod_03_question_server("quiz_numbers", df_questions = df_numbers)
  mod_02_vocab_server("vocab_numbers", df_vocab = df_numbers)

  mod_03_question_server("quiz_food", df_questions = df_food)
  mod_02_vocab_server("vocab_food", df_vocab = df_food)

  mod_03_question_server("quiz_drinks", df_questions = df_drinks)
  mod_02_vocab_server("vocab_drinks", df_vocab = df_drinks)

  mod_03_question_server("quiz_animals", df_questions = df_animals)
  mod_02_vocab_server("vocab_animals", df_vocab = df_animals)

  mod_03_question_server("quiz_question_words", df_questions = df_question_words)
  mod_02_vocab_server("vocab_question_words", df_vocab = df_question_words)

}
