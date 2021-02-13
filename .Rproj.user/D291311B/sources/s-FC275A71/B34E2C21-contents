library(tidyverse)
library(plotly) # interactive charts
library(lubridate) # for dates
library(shiny)
library(DT)

renderPlotly2 <- function (expr, env = parent.frame(), quoted = FALSE){
    if (!quoted) {
        expr <- substitute(expr)
    }
    shinyRenderWidget(expr, plotlyOutput, env, quoted = TRUE)
}

# Founds d.label by looking at source code when hovering (i.e. look for fullData)
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

server <- function(input, output, session) {

    output$roast_profile <- renderPlotly({
        plot_ly(
            haiti,
            type = 'scatter',
            mode = 'lines',
            x = ~ lubridate::as_datetime(Time2),
            line = list(color = "#00007f"),
            # x = ~seq(ms("00:00"), ms("10:10")),
            # x = ~ lubridate::ms(Time2),
            # x = ~ lubridate::as_datetime(Time1),
            y = ~ BT,
            hovertemplate = paste('%{y: 2f}', '<br>%{x:%H %M}<br>'),
            showlegend = FALSE,
            name = "BT"
        ) %>%
            add_trace(
                mode = 'lines',
                x = ~ lubridate::as_datetime(Time2),
                # x = ~ lubridate::ms(Time2),
                # x = ~ lubridate::as_datetime(Time2),
                y = ~ ET,
                line = list(color = "#ff0000"),
                name = "ET"
            ) %>%
            add_trace(
                mode = 'lines',
                x = ~ lubridate::as_datetime(Time2),
                # x = ~ lubridate::ms(Time2),
                # x = ~ lubridate::as_datetime(Time2),
                y = ~ change_BT * 6.25,
                line = list(color = "#0000ff"),
                name = "Ch BT"
            ) %>%
            filter(!is.na(Event),
                   !is.na(Time2),
                   Event != "Drop",
                   !grepl("^Charge", Event)) %>%
            add_annotations(
                # x =  ~jitter(Time2), 
                # y = ~jitter(BT, 30),
                text = ~ Event,
                textposition = "top center",
                arrowhead = .5,
                arrowwidth = 1,
                font = list(size = 12, color = "#ffffff"),
                bgcolor = ~ event_color
            ) %>%
            layout(
                shapes = list(
                    list(
                        type = rect,
                        x0 = time_zero,
                        x1 = max(as_datetime(haiti$Time2), na.rm = TRUE),
                        y0 = 0,
                        y1 = 100,
                        line = list(color = '#d9ecd9'),
                        fillcolor = '#d9ecd9',
                        layer = 'below'
                    ),
                    list(
                        type = rect,
                        x0 = time_zero,
                        x1 = max(as_datetime(haiti$Time2), na.rm = TRUE),
                        y0 = 100,
                        y1 = 300,
                        line = list(color = '#fff1d9'),
                        fillcolor = '#fff1d9',
                        layer = 'below'
                    ),
                    list(
                        type = rect,
                        x0 = time_zero,
                        x1 = max(as_datetime(haiti$Time2), na.rm = TRUE),
                        y0 = 300,
                        y1 = 500,
                        line = list(color = '#efe8e0'),
                        fillcolor = '#efe8e0',
                        #dtick= 59,   tickformat="%M:%S",
                        layer = 'below'
                    ),
                    list(
                        type = rect,
                        x0 = as_datetime(haiti$Time2[grepl("FCs", haiti$Event), "Time2"]),
                        x1 = as_datetime(haiti$Time2[grepl("FCe", haiti$Event), "Time2"]),
                        y0 = 0,
                        y1 = 500,
                        line = list(color = '#ebe134'),
                        fillcolor = '#ebe134',
                        opacity = 0.2,
                        layer = 'below'
                    )
                ),
                xaxis = list(
                    gridcolor = toRGB("gray85"),
                    title = "",
                    zeroline = F,
                    showline = F,
                    showgrid = T,
                    tick0 = time_zero,
                    tickformat = "%M:%S",
                    dtick = 30000
                ),
                yaxis = list(
                    title = "",
                    zeroline = F,
                    showline = F,
                    showgrid = F
                )
            )
    })
    output$hover <- renderText({
        input$hover_data
    })
    output$coffee_tasting <- renderPlotly2({
        # coffee_tasting$name = rownames(coffee_tasting)
        p <- coffee_cupping_tasting %>% plot_ly() %>% add_trace(
            type='sunburst',
            ids=coffee_cupping_tasting$ids,
            labels=coffee_cupping_tasting$end_name,
            parents=coffee_cupping_tasting$parents,
            # name = ~coffee_tasting$name,
            domain=list(column=1),
            maxdepth=3,
            insidetextorientation='radial'
        ) %>%
            layout(
                # grid = list(columns =2, rows = 1),
                margin = list(l = 0, r = 0, b = 0, t = 0))
        as_widget(p) %>% onRender(addHoverBehavior)
    })
    output$coffee_flavors <- renderPlotly({
        coffee_flavors %>% plot_ly() %>% add_trace(
            type='sunburst',
            ids=coffee_flavors$ids,
            labels=coffee_flavors$labels,
            parents=coffee_flavors$parents,
            domain=list(column=1),
            maxdepth=3,
            insidetextorientation='radial'
        ) %>% layout(
                # grid = list(columns =2, rows = 1),
                margin = list(l = 0, r = 0, b = 0, t = 0))
                # sunburstcolorway = c(
                #     "#636efa","#EF553B","#00cc96","#ab63fa","#19d3f3",
                #     "#e763fa", "#FECB52","#FFA15A","#FF6692","#B6E880"
                # ),
                # extendsunburstcolors = TRUE) # This makes colors light with more slices
    })
    
    output$arabica <- renderDT({
        datatable(arab)
        
    })

}
