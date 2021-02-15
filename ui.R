# library(shinydashboard)
# library(shinyWidgets)
# library(htmlwidgets) # need this??
library(shinythemes)
library(plotly)
library(shiny)
library(formattable)

# Define UI for application that draws a histogram
shinyUI(navbarPage(
    theme = shinytheme("united"),
    "Coffee",
    #  -------------- The Roast Profile Tab --------------------
    tabPanel(
        "Roast profiles",
        sidebarLayout(
            column(width = 2,
            sidebarPanel(width = NULL,
                         radioButtons(
                             "plotType", "Plot type",
                             c("Scatter" = "p", "Line" = "l")
                         )),
            sidebarPanel(width = NULL,
                         formattableOutput("roasting_profile_data")
                         # "Dry End: ", textOutput("dry_end", inline = TRUE),br(),
                         # "First Crack: ", textOutput("dry_end2", inline = TRUE)
                         )),
            mainPanel(width = 6, style="text-align:justify;color:black;background-color:rgb(245,245,245);padding:15px;border-radius:10px",
                plotlyOutput("roast_profile"),
                DT::dataTableOutput("scatter2")
            )
        )
        # plotOutput("distPlot")
    ),
    #  -------------- Tasting Tab --------------------
    tabPanel("Tasting",
             fluidRow(
                 column(
                     width = 6,
                     plotlyOutput("coffee_tasting", height = "1000px"),
                     # textOutput('hover')
                     textOutput('click')
                 ),
                 column(width = 6,
                        plotlyOutput("coffee_flavors", height = "1000px"))
             )),
    #  -------------- Upload Data Tab --------------------

    tabPanel("UploadData",
        box(
            width = 6,
            style = "text-align:justify;color:black;background-color:rgb(245,245,245);padding:15px;border-radius:10px",
            fluidRow(
                # column(6,htmlOutput("allocation_week")), # The dropdown menu),
                column(2, htmlOutput("get_country")),
                column(2, textInput("roast_date", "Roast date")),
                column(2, textInput("weight_before", "Weight before")),
                column(2, textInput("weight_after", "Weight after")),
            ),
            fluidRow(
                # column(2, textInput("roast_machine", "Machine")),
                column(2, htmlOutput("get_roast_machine")),
                column(4, textInput("roast_farm", "Bean farm")),
                column(4, textInput("primary_key", "primary Key")),
                column(2, textInput("quality", "Quality (if known)"))
            ),
            # column(6,textInputAddon(inputId = "loc_ship_address", label = "Address", placeholder = "Username", addon = icon("at"))),
            fluidRow(
                column(2, htmlOutput("get_processing_method")),
                column(2, htmlOutput("get_variety")),
                column(8, textAreaInput("roast_notes", "Roast notes"))
            ),
            fluidRow(column(
                4,
                actionButton("new_record", "New profile")
            ),
            column(
                4,
                actionButton("update_record", "Update profile")
            )),
            hr(),
            fluidRow(column(
                5, # Only able to import xlsx
                fileInput('roast_curves_upload', 'upload xlsx', accept = '.xlsx')
            ),
            column(
                3,
                actionButton('attach_file_to_profile', "Attach to profile"), #need?
                offset = 0
            ))
        )
    )
    #  -------------- More Tabs -dropdown --------------------
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
