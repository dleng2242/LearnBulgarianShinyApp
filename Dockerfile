FROM learnbulgarianshinyapp_base:0.1
COPY renv.lock renv.lock
RUN R -e 'renv::restore()'
COPY LearnBulgarianShinyApp_*.tar.gz /app.tar.gz
RUN R -e 'remotes::install_local("/app.tar.gz",upgrade="never")'
RUN rm /app.tar.gz
EXPOSE 80
CMD R -e "options('shiny.port'=80,shiny.host='0.0.0.0');library(LearnBulgarianShinyApp);LearnBulgarianShinyApp::run_app()"
