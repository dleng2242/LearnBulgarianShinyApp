## code to make internal vocab datasets

df_cyrillic <- readr::read_csv("data-raw/bulgarian_cyrillic_alphabet.csv")
df_numbers <- readr::read_csv("data-raw/bulgarian_numbers.csv")
df_food <- readr::read_csv("data-raw/bulgarian_food.csv")
df_drinks <- readr::read_csv("data-raw/bulgarian_drinks.csv")
df_animals <- readr::read_csv("data-raw/bulgarian_animals.csv")
df_question_words <- readr::read_csv("data-raw/bulgarian_questions.csv")
df_calendar <- readr::read_csv("data-raw/bulgarian_calendar.csv")

usethis::use_data(
  df_cyrillic,
  df_numbers,
  df_food,
  df_drinks,
  df_animals,
  df_question_words,
  df_calendar,
  overwrite = TRUE, 
  internal = TRUE
)
