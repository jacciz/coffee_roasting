library(tidyverse)    # includes tidyr, tibble, and more
library(lubridate)    # for working with dates, need this for data import
library(readxl)


haiti <- read_xlsx("21-02-09_2015_Haiti_Baptiste.xlsx", skip = 3) %>% select(1:6) %>% rename(change_BT = "Δ BT")
# haiti$Time2 %>% typeof()
haiti <- haiti %>% mutate(Time2 = lubridate::ms(Time2))

# could also change height of fan
# maillard rgb(247,198,111)
haiti[grepl("Heat", haiti$Event), "event_color" ] <- "#f71212"
haiti[grepl("Fan", haiti$Event), "event_color" ] <- "#0d0dff"
haiti[grepl("FC", haiti$Event), "event_color" ] <- "#c5a872"
haiti[grepl("Dry End", haiti$Event), "event_color" ] <- "#77b36f"
haiti[grepl("Charge", haiti$Event), "event_color" ] <- "#222921"

time_zero = as_datetime("1970-01-01 00:00:00 UTC")

# https://perfectdailygrind.com/2016/02/the-world-coffee-research-sensory-lexicon-its-new-but-is-it-finished/
# https://towardsdatascience.com/analyzing-sweet-marias-coffee-cupping-metrics-3be460884bb1
arab = read.csv('data/arabica_data_cleaned.csv')
coffee_flavors = read.csv("data/sunburst-coffee-flavors-complete.csv")
coffee_cupping_tasting = readxl::read_xlsx('C:/W_shortcut/coffee_roasting/data/coffee-flavors_lexicon.xlsx')
# coffee_cupping_tasting = read.csv('data/coffee-flavors.csv')