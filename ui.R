# library(shinydashboard)
# library(shinyWidgets)
# library(htmlwidgets) # need this??
library(shinythemes)
library(plotly)
library(shiny)

# Define UI for application that draws a histogram
shinyUI(navbarPage(
    theme = shinytheme("united"),
    "Coffee",
    tabPanel("Roast profiles",
             sidebarLayout(
                 sidebarPanel(width = 2,
                              radioButtons(
                     "plotType", "Plot type",
                     c("Scatter" = "p", "Line" =
                           "l")
                 )),
                 mainPanel(
                     plotlyOutput("roast_profile")
                     )
             )
             # plotOutput("distPlot")
             ),
    tabPanel("Tasting",
             fluidRow(
                 column(width = 6,
             plotlyOutput("coffee_tasting"),
             textOutput('hover')),
             column(width = 6,
             plotlyOutput("coffee_flavors")
             ))
             )
             # DTOutput("arabica"))
    # navbarMenu(
    #     "More",
    #     tabPanel("Table",
    #              DT::dataTableOutput("table")),
    #     tabPanel("About",
    #              fluidRow(column(
    #                  6,
    #                  # includeMarkdown("about.md")),
    #                  column(6
    #                  )
    #              )))
    # )
))
