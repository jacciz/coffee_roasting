library(shinydashboard) # box
library(shinyWidgets) # More buttons than base shiny # https://github.com/dreamRs/shinyWidgets
# library(htmlwidgets) # need this??
library(shinythemes)
library(plotly)
library(shiny)
library(formattable)
# library(shiny.semantic) # wrappers for a better look https://appsilon.github.io/shiny.semantic/
# library(shinyreforms) # for forms https://cran.r-project.org/web/packages/shinyreforms/vignettes/tutorial.html

# Define UI for application that draws a histogram
shinyUI(
    navbarPage(
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
            mainPanel(width = 8, style="text-align:justify;color:black;background-color:rgb(245,245,245);padding:15px;border-radius:10px",
                plotlyOutput("roast_profile", height = "500px")
                # DT::dataTableOutput("scatter2")
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
                     # textInput("names")
                 ),
                 column(width = 6,
                        plotlyOutput("coffee_flavors", height = "1000px"))
             )),
    #  -------------- Upload Data Tab --------------------

    tabPanel("Update Data",
        box(
            width = 6,
            style = "text-align:justify;color:black;background-color:rgb(245,245,245);padding:15px;border-radius:10px",
            # fluidRow(
            #     # column(6,htmlOutput("allocation_week")), # The dropdown menu),
            #     column(2, htmlOutput("get_country")),
            #     column(2, textInput("roast_date", "Roast date")),
            #     column(2, textInput("weight_before", "Weight before")),
            #     column(2, textInput("weight_after", "Weight after")),
            # ),
            # fluidRow(
            #     # column(2, textInput("roast_machine", "Machine")),
            #     column(2, htmlOutput("get_roast_machine")),
            #     column(4, shiny.semantic::textInput("roast_farm", "Bean farm")),
            #     column(4, textInput("primary_key", "primary Key")),
            #     column(2, textInput("quality", "Quality (if known)"))
            # ),
            # # column(6,textInputAddon(inputId = "loc_ship_address", label = "Address", placeholder = "Username", addon = icon("at"))),
            # fluidRow(
            #     column(2, htmlOutput("get_processing_method")),
            #     column(2, htmlOutput("get_variety")),
            #     column(8, textAreaInput("roast_notes", "Roast notes"))
            # ),
            fluidRow(column(
                4,
                actionButton("new_record", "New profile")
            ),
            column(
                4
                # actionButton("update_record", "Update profile")
            )),
            hr(),
            fluidRow(column(
                5, # Only able to import xlsx
                # shiny.semantic::semanticPage(
                    shiny.semantic::fileInput('roast_curves_upload', 'upload xlsx', accept = '.xlsx', width = "400px", type = "small")
                #     h3("File type uploaded"),
                #     textOutput("file_ex")
                # )
                # fileInput('roast_curves_upload', 'upload xlsx', accept = '.xlsx')
            )
            # column(
                # 3,
                # actionButton('attach_file_to_profile', "Attach to profile"), #need?
                # offset = 0
            # )
            )
        )
    ),
    #  -------------- Upload Data Tab --------------------
    shinyFeedback::useShinyFeedback(), # Need this in ui for Feedback to work
    tabPanel(
        "Import Data",
        box(titlePanel("Input Profile"),
            width = 4,
            style = "text-align:justify;color:black;background-color:rgb(245,245,245);padding:15px;border-radius:10px",
            fluidRow(
                column(3, shiny::dateInput("roast_date", "Roast date", value = Sys.Date(), format = "M d, yyyy", autoclose=TRUE)),
                # input sys date
                column(3, textInput("name", "Your name")),
                column(2, numericInput("weight_before", "Weight before", value = NA)),
                column(2, numericInput("weight_after", "Weight after", value = NA)),
                column(2, pickerInput("unit_of_measure", "Units", choices = units_of_measures, options = pickerOptions())),
            ),
            fluidRow(
                column(3, pickerInput("roast_machine", "Roast machine", choices = coffee_roasting_machines)),
                column(3, textInput("roast_farm", "Farm")),
                column(3, pickerInput("country", "Country", choices = coffee_producting_countries)),
                column(3, textInput("region", "Region"))
            ),
            fluidRow(
                column(3, textInput("quality", "Quality")),
                column(3, pickerInput("processing_method", "Processing methods", choices = processing_methods)),
                column(3, selectInput("variety", "Variety", choices = coffee_varieties_arabica, multiple = TRUE)),
                column(3, textAreaInput("roast_notes", "Notes")),
                
            ), # https://mastering-shiny.org/action-transfer.html
            fluidRow(shiny::fileInput(inputId = 'roast_curves_upload', 'Upload Artisan (.alog)', accept = '.alog'),
                actionButton("update_record", "Submit", class = "btn-primary")
            ),
            formattableOutput("uploaded_data_preview")
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
