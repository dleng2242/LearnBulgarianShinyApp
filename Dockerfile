FROM learnbgregistry.azurecr.io/learnbulgarianshinyapp_base:latest
COPY renv.lock renv.lock
RUN R -e 'renv::restore()'
COPY . LearnBulgarianShinyApp
RUN R -e 'remotes::install_local("/LearnBulgarianShinyApp",upgrade="never")'
EXPOSE 80
CMD R -e "options('shiny.port'=80,shiny.host='0.0.0.0');library(LearnBulgarianShinyApp);LearnBulgarianShinyApp::run_app()"
