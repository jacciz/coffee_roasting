library(tidyverse)
library(plotly) # interactive charts
library(lubridate) # for dates
library(shiny)
library(DT)
library(formattable)
library(shinyWidgets)
# library(shinyvalidate)
library(shinyFeedback) # https://github.com/merlinoa/shinyFeedback and https://mastering-shiny.org/action-feedback.html, good for a single input, validate() is for output

# filter(.data[[input$var]] > .env$input$min)) or diamonds %>% filter(.data[[var]] > .env$min)
# create dynamic and multiple dropwdowns: https://mastering-shiny.org/action-dynamic.html
# ctrl shift enter
# jobs in C:\Users\dotjaz\Documents\RStudio\background-jobs view: rstudioapi::viewer("http://127.0.0.1:5101")
# traceback() to find error location, add browser() in code to launch debugger
# breakpoints - debugger tool - press n,c,q
# use message() glue::glue() str()
# selectVarServer("var", reactive(input$x)))
# ctrl .  to find function
# Testing: https://mastering-shiny.org/scaling-testing.html
# Performance: https://mastering-shiny.org/performance.html

# list(
#   name = reactive(input$var),
#   value = reactive(data()[[input$var]])
# )

# Use this to show select / hover Plotly data
renderPlotly2 <-
    function (expr,
              env = parent.frame(),
              quoted = FALSE) {
        if (!quoted) {
            expr <- substitute(expr)
        }
      htmlwidgets::shinyRenderWidget(expr, plotlyOutput, env, quoted = TRUE)
    }

# Javascript to get the output
# Found d.label by looking at source code when hovering (i.e. look for fullData)
addHoverBehavior <- "function(el, x){
  el.on('plotly_hover', function(data){
    var infotext = data.points.map(function(d){
      console.log(d)
      return ('label: '+d.label+' parent: ' + d.parent);
    });
    console.log(infotext)
    Shiny.onInputChange('hover_data', infotext)
  })
}"
# Same but with capturing the click data
addClickBehavior <- "function(el, x){
  el.on('plotly_click', function(data){
    var infotext = data.points.map(function(d){
      console.log(d)
      return (d.label);
    });
    console.log(infotext)
    Shiny.onInputChange('click_data', infotext)
  })
}"

server <- function(input, output, session) {
    # data = list_data[2,]
    # table = "roast_profiles"
    # ------------------------- Save / Update Data Functions  --------------------------------------
    # Functions to save data to SQL table depending on which table:
    save_data_in_roast_profiles <-
        function(data, table) { # Data is matched via ID_Key
            # print(get_where_clause())
            if (length(data != 0)) { # verify there is data to be changed
                if (input$primary_key == 0 |
                    input$primary_key == '') {   # If no primary key, insert record instead
                    sql <- paste0(
                        "INSERT INTO ?table (",
                        paste0(names(data), collapse = ", "),
                        ") VALUES (",
                        paste0("?", names(data), collapse = ", "),
                        ")"
                    )
                    query <- sqlInterpolate(pool, sql, .dots = c(list(table = table),
                                                                 data))
                    # print(query)
                    record_status <- "inserted."
                } else {
                    # Construct the update query
                    sql <- paste0(
                        "UPDATE ?table SET ",
                        paste0(names(data), " = ?", names(data), collapse = ", "),
                        " WHERE ",
                        "primary_key",  # what to match with ?>?
                        " = ?idVal;"
                    )
                    query <- sqlInterpolate(pool, sql, .dots = c(
                        list(table = table),
                        as.list(data),
                        list(idVal = input$primary_key)
                    ))
                    record_status <- "updated."
                }
                # Submit query and disconnect
                dbExecute(pool, query)
            } else {
                record_status <- "not updated." # if no data?
            }
            record_status # Return if either inserted or updated
        }
    
    upload_roast_profiles <-
      function(data, table) {
        
        if (length(data != 0)) { # verify there is data to be changed
            sql <- paste0(
              "INSERT INTO ?table (",
              paste0(names(data), collapse = ", "),
              ") VALUES (",
              paste0("?", names(data), collapse = ", "),
              ")"
            )
            query <- sqlInterpolate(pool, sql, .dots = c(list(table = table),
                                                         data))
            # Submit query and disconnect
            dbExecute(pool, query)
        }
            record_status <- "inserted."
      }
            
    # ------------------------- Reactives  --------------------------------------
    # 
    # get_selected_profile <- # Based on country for now
    #     reactive({
    #         dbReadTable(pool, "roast_profiles") %>% filter(country == input$country)# filter(Org_Name %in% input$health_clinic)
    #     })
    
    # When selected data changes, table gets updated
    # jittered_iris <- reactive({
    #     haiti
    # })
    # 
    # shared_iris <- SharedData$new(jittered_iris)
    # 
    # roasting_profile_data <- reactive({
    #     # get_roasting_profile_data <- function(haiti) {
    #     df = haiti
    #         chart_analysis <- c(
    #             time_zero = "1970-01-01 00:00:00 UTC",
    #             charge_start = format(as_datetime(df$Time2[grepl("Charge", df$Event), "Time2"]), format = "%M:%S"),
    #             time_max = format(max(as_datetime(df$Time2), na.rm = TRUE), format = "%M:%S"),
    #             dry_end = format(as_datetime(df$Time2[grepl("Dry End", df$Event), "Time2"]), format = "%M:%S"),
    #             first_crack_start = format(as_datetime(df$Time2[grepl("FCs", df$Event), "Time2"]), format =  "%M:%S"),
    #             first_crack_end = format(as_datetime(df$Time2[grepl("FCe", df$Event), "Time2"]), format = "%M:%S"),
    #             drop_start = format(as_datetime(df$Time2[grepl("Drop", df$Event), "Time2"]), format = "%M:%S"),
    #             max_temp = 500,
    #             # Highest temp in chart
    #             end_temp = as.numeric(df[grepl("Drop", df$Event), "BT"])
    #         ) %>% as.list()
    #         chart_analysis
    #     # }
    # })

    #  -------------- The Roast Profile Analysis Line Chart --------------------  
    output$roasting_profile_data <- renderFormattable({ 
        
    get_roasting_profile_data <- function(df) {
        chart_analysis <- c(
            time_zero = "1970-01-01 00:00:00 UTC",
            charge_start = format(as_datetime(df$Time2[grepl("Charge", df$Event), "Time2"]), format = "%M:%S"),
            time_max = format(max(as_datetime(df$Time2), na.rm = TRUE), format = "%M:%S"),
            dry_end = format(as_datetime(df$Time2[grepl("Dry End", df$Event), "Time2"]), format = "%M:%S"),
            first_crack_start = format(as_datetime(df$Time2[grepl("FCs", df$Event), "Time2"]), format =  "%M:%S"),
            first_crack_end = format(as_datetime(df$Time2[grepl("FCe", df$Event), "Time2"]), format = "%M:%S"),
            drop_start = format(as_datetime(df$Time2[grepl("Drop", df$Event), "Time2"]), format = "%M:%S"),
            # max_temp = 500, # Highest temp in chart
            end_temp = as.character(as.numeric(df[grepl("Drop", df$Event), "BT"]))
        ) %>% as.list()
        
        chart_analysis
    }
    chart_analysis <- get_roasting_profile_data(haiti)
    
    # Do calculations, finalize numbers and time to make into a table
    chart_analysis <-
        chart_analysis %>% as.data.frame() %>% mutate(
            duration = ms(drop_start) - ms(charge_start),
            dev_time = ms(drop_start) - ms(first_crack_start),
            duration = format(as_datetime(duration), format = "%M:%S"),
            dev_ratio = paste0(round(ms(dev_time) * 100 / ms(duration), 1), "%"),
            dev_time = format(as_datetime(dev_time), format = "%M:%S"),
            end_temp = round(as.numeric(end_temp), 1)
        ) %>% mutate_all(as.character) %>% select(
            "First crack" = first_crack_start,
            "Roast duration" = duration,
            "Development time" = dev_time,
            "Dev. time ratio" = dev_ratio,
            "End temp.(\u00b0F)" = end_temp
            # "End temp." = paste0(end_temp, "\u00b0F")
        )
    
    # make a datatable for output
    chart_analysis %>% pivot_longer(cols = 1:5, values_to = "data") %>% formattable(., list(
        name = formatter("span", style = "color:#AAAAAA; font-size:14px; font-weight:bold;"),
        data = formatter("span", style = "color:grey;")
    ))
    })
    #  -------------- The Roast Profile --------------------
    output$roast_profile <- renderPlotly({
        # Get data for certain parameters for chart
        # data <- roasting_profile_data()
        time_zero = as_datetime("1970-01-01 00:00:00 UTC")
        time_max = max(as_datetime(haiti$Time2), na.rm = TRUE)
        dry_end = as_datetime(haiti$Time2[grepl("Dry End", haiti$Event), "Time2"])
        first_crack_start = as_datetime(haiti$Time2[grepl("FCs", haiti$Event), "Time2"])
        first_crack_end = as_datetime(haiti$Time2[grepl("FCe", haiti$Event), "Time2"])
        drop_start = as_datetime(haiti$Time2[grepl("Drop", haiti$Event), "Time2"])
        max_temp = 500 # Highest temp in chart
        # print(haiti$Time2)
        plot_ly(
            # BT Line
            haiti,
            type = 'scatter',
            mode = 'lines',
            x = ~ lubridate::as_datetime(Time2),
            line = list(color = "#4DB848"),
            # x = ~seq(ms("00:00"), ms("10:10")),
            # x = ~ lubridate::ms(Time2),
            # x = ~ lubridate::as_datetime(Time1),
            y = ~ BT,
            # hovertemplate = paste('%{y: .1f}\u00b0F', '<br>%{x}<br>'),
            hovertemplate = '%{y: .1f}\u00b0F',
            showlegend = FALSE,
            name = "BT"
        ) %>%
            add_trace(         # ET Line
                mode = 'lines',
                x = ~ lubridate::as_datetime(Time2),
                y = ~ ET,
                line = list(color = "#D50032"),
                name = "ET"
            ) %>%
            add_trace(        # Change BT Line
                mode = 'lines',
                x = ~ lubridate::as_datetime(Time2),
                y = ~ change_BT,
                line = list(color = "#428BCA"),
                name = "\u0394BT",
                yaxis = "y2"
            ) %>% layout(hovermode = "x unified") %>%
            filter(!is.na(Event),
                   !is.na(Time2),
                   Event != "Drop",
                   !grepl("^Charge", Event)) %>%
            add_annotations(
                # x =  ~lubridate::as_datetime(Time2), # jitter() ?
                # y = ~ jitter(BT, 60),
                text = ~ Event,
                # yaxis = "y2",
                textposition = "top center",
                arrowhead = .5,
                arrowwidth = 1,
                font = list(size = 12, color = "#ffffff"),
                bgcolor = ~ event_color
            ) %>%                     # Add lines for phases
            add_segments( x = ~dry_end, xend = ~dry_end, y =~ 0, yend=~500,
                          # opacity = 1,
                line = list(dash="dash",
                    color = '#AAAAAA',
                    width = 2), text = "Dry end") %>% 
            add_segments( x = ~first_crack_start, xend = ~first_crack_start, y =~ 0, yend=~500,
                          # opacity = 1,
                          line = list(dash="dash",
                                      color = '#AAAAAA',
                                      width = 2), text = "FC start") %>% 
            add_segments( x = ~first_crack_end, xend = ~first_crack_end, y =~ 0, yend=~500,
                          # opacity = 1,
                          line = list(dash="dash",
                                      color = '#AAAAAA',
                                      width = 2), text = "FC start") %>% 
            # For second_crash_start
            # add_segments( x = ~first_crack_start, xend = ~first_crack_start, y =~ 0, yend=~500,
            #               # opacity = 1,
            #               line = list(dash="dash",
            #                           color = 'gray80',
            #                           width = 2), text = "FC start") %>% 
            layout(
                # The right side y-axis
                yaxis2 = list(
                    zeroline = F,
                    showline = F,
                    showgrid = F,
                    tickfont = list(color = "#428BCA"),
                    ticksuffix = "\u00b0F",
                    overlaying = "y",
                    side = "right",
                    title = ""
                ),
                # shapes = list(
                #     list(
                #         type = rect,
                #         x0 = time_zero,
                #         x1 = dry_end,
                #         y0 = 0,
                #         y1 = max_temp,
                #         line = list(color = '#d9ecd9'),
                #         fillcolor = '#d9ecd9',
                #         opacity = 0.2,
                #         layer = 'below'
                #     ),
                #     list(
                #         type = rect,
                #         x0 = dry_end,
                #         x1 = first_crack_start,
                #         y0 = 0,
                #         y1 = max_temp,
                #         line = list(color = '#fff1d9'),
                #         fillcolor = '#fff1d9',
                #         opacity = 0.2,
                #         layer = 'below'
                #     ),
                #     list(
                #         type = rect,
                #         x0 = first_crack_start,
                #         x1 = drop_start,
                #         y0 = 0,
                #         y1 = 500,
                #         line = list(color = '#efe8e0'),
                #         fillcolor = '#efe8e0',
                #         opacity = 0.2,
                #         layer = 'below'
                #     )
                # ),
                xaxis = list(
                    # gridcolor = toRGB("gray85"),
                    title = "",
                    zeroline = F,
                    showline = F,
                    showgrid = F,
                    tick0 = time_zero,
                    ticks = "inside",
                    tickcolor = "grey80",
                    tickformat = "%M:%S",
                    dtick = 30000 # Tick every 30 seconds
                ),
                yaxis = list(
                    title = "",
                    ticksuffix = "\u00b0F",
                    zeroline = F,
                    showline = F,
                    showgrid = F
                ),
                margin = list(
                    r = 30,
                    l = 0,
                    b = 0,
                    t = 0
                ),
                plot_bgcolor = 'rgb(245,245,245)',
                # make grey background
                paper_bgcolor = 'rgb(245,245,245)'
            )
    })
    #  -------------- The Roast Profile datatable --------------------
    # output$scatter2 <- DT::renderDataTable({
    #     datatable(shared_iris)
    # }, server = FALSE)
    # 
    output$hover <- renderText({
        input$hover_data
    })
    output$click <- renderText({
        input$click_data
    })
    
    # Accumulate flavor notes when clicked - https://mastering-shiny.org/reactivity-components.html
    # flavor <- reactiveValues(names = character())
    # observeEvent(input$click_data, {
    #   flavor$names <- c(input$click_data, flavor$names)
    #   updateTextInput(session, "notes", value = "")
    # })
    # output$names <- renderText(names())
    
    # input = click_data  output = click
    r <- reactiveValues(click = character())
    observeEvent(input$click_data, {
      # print(input$click_data) # works
      r$click <- union(input$click_data, r$click)
      print(r$click)# works
      # updateTextInput(session, "click_data", value = "")
    })
    
    # output$click <- renderText(click())

    
    #  -------------- Coffee Cupping Sunburst --------------------
    output$coffee_tasting <- renderPlotly2({
        coffee_cupping_tasting <- coffee_cupping_tasting %>% mutate(new_label =paste0("<b>",end_name,": ", "</b>",stringr::str_wrap(labels, width = 30)))
        # coffee_tasting$name = rownames(coffee_tasting)
        p <- coffee_cupping_tasting %>% plot_ly() %>% add_trace(
            type = 'sunburst',
            ids = coffee_cupping_tasting$ids,
            labels = coffee_cupping_tasting$end_name,
            parents = coffee_cupping_tasting$parents,
            text = ~coffee_cupping_tasting$new_label,
            textinfo = 'label',  # What shows on the chart
            hovertemplate = '%{text}',
            domain = list(column = 1),
            maxdepth = 3,
            insidetextorientation = 'radial'
        ) %>%  
            layout(# grid = list(columns =2, rows = 1),
                margin = list(
                    l = 0,
                    r = 0,
                    b = 0,
                    t = 0
                )) %>% 
        as_widget(p) %>%
          htmlwidgets::onRender(addClickBehavior)#onRender(addHoverBehavior)
    })
    #  -------------- Coffee Tasting Sunburst --------------------
    output$coffee_flavors <- renderPlotly({
        coffee_flavors %>% plot_ly() %>% add_trace(
            type = 'sunburst',
            ids = coffee_flavors$ids,
            labels = coffee_flavors$labels,
            parents = coffee_flavors$parents,
            domain = list(column = 1),
            maxdepth = 3,
            insidetextorientation = 'radial'
        ) %>% layout(# grid = list(columns =2, rows = 1),
            margin = list(
                l = 0,
                r = 0,
                b = 0,
                t = 0
            ))
        # sunburstcolorway = c(
        #     "#636efa","#EF553B","#00cc96","#ab63fa","#19d3f3",
        #     "#e763fa", "#FECB52","#FFA15A","#FF6692","#B6E880"
        # ),
        # extendsunburstcolors = TRUE) # This makes colors light with more slices
    })
    
    #  -------------- Chart of QCI --------------------
    # output$arabica <- renderDT({
    #     datatable(arab)
    # })
    
    #  -------------- Input Roast Data from file/user --------------------    
    # Example: https://www.youtube.com/user/RodCoelho/search?query=MySQL Don't need loadDropdown as we are not deleting records
    
    
    

    # # name
    # list_data <- loadData(c("primary_key", "roast_date", "country"), "roast_profiles") %>% as.data.frame()
    # list_data <- rbind(data.frame("primary_key" = 0, "roast_date" = Sys.Date(), "country" = "Other"),list_data) # Adds a new row of empty values
    # # country_list <- setNames(nm = c(list_data$primary_key, list_data$roast_data, list_data$country)) # strips the header names
    # names(list_data) <- NULL
    # # output$get_primary_key <- renderUI({  
    # #     selectInput("selected_primary_key", "primary Keys", country_list, width = '100%', selected = NULL)
    # # })
    # 
    # list_data <- loadData(c("roast_date", "country"), "roast_profiles") %>% as.data.frame()
    # list_data <- rbind(data.frame("roast_date" = Sys.Date(), "country" = "None"),list_data) # Adds a new row of empty values
    # # country_list <- setNames(nm = c( list_data$roast_data, list_data$country)) # strips the header names
    # names(list_data) <- NULL # Strip header
    # output$get_primary_key <- renderUI({
    #     selectInput("selected_primary_key", "primary Keys", country_list, width = '100%', selected = NULL)
    # })

    
    #  -------------- Input Roast Data - Dropdowns for Form --------------------     
# Make dropdown menu of all countries, roast machines, 
    output$get_country <- renderUI({
        # countries <- get_selected_profile()$country
        countries <- coffee_producting_countries
        # primary_key_list <- filtered_orders_with_contacts()$primary_key
        # print(primary_key_list) #does print list
        # print(filtered_orders_with_contacts()) works
        pickerInput("country", "Country", countries, width = '100%', selected = NULL)
    })
    output$get_roast_machine <- renderUI({
        machines <- coffee_producting_countries %>% sort()
        pickerInput("roast_machine", "Machine", coffee_roasting_machines, width = '100%', selected = NULL)
    })
    output$get_processing_method <- renderUI({
        method <- processing_methods %>% sort()
        pickerInput("processing_method", "Processing method", method, width = '100%', selected = NULL)
    })
    output$get_variety <- renderUI({
        varieties <- coffee_varieties_arabica %>% sort()
        pickerInput("variety", "Variety", varieties, width = '100%', selected = NULL)
    })
    #  -------------- Input Roast Data from file/user --------------------  
    # When Country is changed, load the form data
    observeEvent(input$country, { # Inputs on the form. Be sure fields will be updated under 'fields_to_update_for_contacts'
        # print(filtered_orders_with_contacts())
        # print(input$selected_primary_key)
        # loaded_form_data <- get_selected_profile() #%>% filter(country == input$selected_country) #%>% as.data.frame()
        
        # updateTextInput(inputId = "roast_date", value = loaded_form_data$roast_date)
        # updateTextInput(inputId = "primary_key", value = loaded_form_data$primary_key)
        # # updateTextInput(inputId = "name", value = loaded_form_data$name)
        # updateTextInput(inputId = "weight_before", value = loaded_form_data$weight_before)
        # updateTextInput(inputId = "weight_after", value = loaded_form_data$weight_after)
        # updateTextInput(inputId = "roast_machine", value = loaded_form_data$roast_machine) #??
        # updateTextInput(inputId = "roast_farm", value = loaded_form_data$roast_farm)
        # # updateTextInput(inputId = "country", value = loaded_form_data$country)
        # updateTextInput(inputId = "region", value = loaded_form_data$region)
        # updateTextInput(inputId = "quality", value = loaded_form_data$loc_ship_city)
        # updateTextInput(inputId = "processing_method", value = loaded_form_data$processing_method)
        # updateTextInput(inputId = "variety", value = loaded_form_data$variety)
        # # updateTextAreaInput(inputId = "roast_notes", value = loaded_form_data$roast_notes)
        # updateTextAreaInput(inputId = "roast_notes", value = input$click_data) # works, kind of?
    })
    
    # Define fields we want to save on the form, this is based on the textInput IDs
    fields_to_update_for_contacts <-
        c(  "roast_date",
            # "primary_key",
            # "name",
            "weight_before",
            "weight_after",
            # unit_of_measure
            "roast_machine",
            "roast_farm",
            "country",
            "region",
            "quality",
            "processing_method",
            # "variety",
            "roast_notes")
 
    # Collect the form data and save it into the "data" list variable
    form_data_contact_db <- reactive({
        # print( input[[contact_register_fields[1]]]) # works
        
        data <- sapply(fields_to_update_for_contacts, function(x) input[[x]] ) # fields contains all values we want to save, gather all the values based on input
        data <- Filter(function(x) !(all(x == "" | x == 0)), data) # take out 0 or empty values
        data
    })

    # Read the data, validate it's xlsx. req() is to wait for file to load. Try this!. Download data: https://mastering-shiny.org/action-transfer.html
    # data <- reactive({
    #   req(input$file)
    #   
    #   ext <- tools::file_ext(input$file$name)
    #   switch(ext,
    #          csv = vroom::vroom(input$file$datapath, delim = ","),
    #          tsv = vroom::vroom(input$file$datapath, delim = "\t"),
    #          validate("Invalid file; Please upload a .csv or .tsv file")
    #   )
    # })
    
    # This check to see if uploaded profile is valid, returns booleon
    valid_profile_upload <- reactive({
      if (any(c(
        length(input$roast_curves_upload$datapath) != 0 &
        !is.null(input$roast_curves_upload) &
        str_sub(input$roast_curves_upload$datapath, -5, -1) == ".alog"
      ))) {
        return(TRUE)
      }
      return(FALSE)
    })

    # When submit button is pushed, save the form data - it doesn't change the data - just saves it ??
    observeEvent(input$update_record, {
      
      # After button is pushed, check for these validations, if not satisfied a message will pop
      feedbackWarning(
        "weight_before",
        !is.numeric(input$weight_before) |
          input$weight_before <= 0,
        "Enter valid number"
      )
      feedbackWarning(
        "weight_after",
        !is.numeric(input$weight_after) |
          input$weight_after <= 0,
        "Enter valid number"
      )

      feedbackWarning("variety", is.null(input$variety), "Enter variety")
      
      # Conditions we want all to be true. Returns true if all are met.
      is_file_valid <- any(c(length(input$roast_curves_upload$datapath) != 0 &
                           !is.null(input$roast_curves_upload) &
                           str_sub(input$roast_curves_upload$datapath, -5, -1) == ".alog")) # Input file must end in .alog

      feedbackWarning(
        "roast_curves_upload", !is_file_valid,
        "Input .alog"
      )

      # And then require these to be valid. If they are all valid, code will finally proceed.
      req(
        is.numeric(input$weight_before) & input$weight_before > 0,
        is.numeric(input$weight_after) & input$weight_after > 0,
        !is.null(input$variety),
        is_file_valid
      )
      # sub <- input$roast_curves_upload$datapath
      # print(sub)
      # Then open alog, returns a long string
      opened_json <- open_profile_as_json(alog_input = input$roast_curves_upload$datapath)
      
      # Convert opened JSON into R format :)
      profile_as_json <- jsonlite::fromJSON(opened_json)
      # print(profile_as_json) works
      # Get the filename as where it is saved so we can save and store filename
      # Returns filename (i.e. data/filename.json)
      saved_filename <- get_profile_filename(profile_as_json,
                                country = input$country,
                                region = input$region)

      # Saves opened JSON profile in the folder. Cannot be an R object.
      write(opened_json, saved_filename)

      # Make the filename list so we can append to all_inputs_to_save
      save_filename_list <- c("filename" = saved_filename) %>% as.list()

      # Variety is saved as a list, must convert to a string and put string into a list to save to db
      variety_as_char <-
        as.character(input$variety) %>% stringr::str_flatten(., collapse = ", ")
      save_variety <- c("variety" = variety_as_char) %>% as.list()
      
      # Combine variety and filename to all inputs (which form_data_contact_db runs) in order to dump them in db under 1 sql query
      # These all must be in fields_to_update_for_contacts in order to save
      all_inputs_to_save <-
        unlist(c(save_variety, save_filename_list, form_data_contact_db()))

      # Then save all the inputs!
      record_status <-
        upload_roast_profiles(all_inputs_to_save, "roast_profiles") # name of db table
      
      showModal(modalDialog(
        title = "Update Success",
        paste("Record was ", record_status),
        easyClose = TRUE
      ))
    })
    
    # When the new button is pushed, need session object so clear out fields
    update_profile_fields <- function(profile_data) {
      profile <- profile_data
        # updateTextInput(session, inputId = "primary_key", value = '')
        # updateTextInput(session, inputId = "", value = as.Date(Sys.Date()))
        # updateTextInput(session, inputId = "name", value = '')
        # updateTextInput(session, inputId = "weight_before", value = '')
        # updateTextInput(session, inputId = "weight_after", value = '')
        # # updateTextInput(session, inputId = "roast_machine", value = '')
        # updateTextInput(session, inputId = "roast_farm", value = '')
        # # updateTextInput(session, inputId = "country", value = '')
        # updateTextInput(session, inputId = "region", value = '')
        # updateTextInput(session, inputId = "quality", value = '')
        # # updateTextInput(session, inputId = "processing_method", value = '')
        # # updateTextInput(session, inputId = "variety", value = '')
      
        # updateTextAreaInput(session, inputId = "roast_notes", value = profile$roastingnotes)
    }
    
    output$uploaded_data_preview <- renderFormattable({
      if (valid_profile_upload()){
        opened_json <- open_profile_as_json(alog_input = input$roast_curves_upload$datapath)
      message(input$roast_curves_upload$datapath)
      
      # Convert opened JSON into R format :)
      profile_as_json <- jsonlite::fromJSON(opened_json)
      x <- profile_as_json$svValues %>% as.data.frame()
      print(x)
        formattable(x)
        } else{
          return(NULL)
        }
    })
}
