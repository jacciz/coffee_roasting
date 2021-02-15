library(tidyverse)    # includes tidyr, tibble, and more
library(lubridate)    # for working with dates, need this for data import
library(readxl)
library(RSQLite)
library(pool)

# Create database connection to SQLite database
pool <- dbPool(RSQLite::SQLite(), dbname = "data/roasting_profiles.db")
# pool <- dbPool(RSQLite::SQLite(), dbname = "C:/W_shortcut/vaccine_distribution/data/vaccine_inventory.db") # TEST LINK
# NON Pool
# pool <- dbConnect(RSQLite::SQLite(), dbname = "data/vaccine_inventory.db")
# pool <- dbConnect(RSQLite::SQLite(), dbname = "C:/W_shortcut/vaccine_distribution/data/vaccine_inventory.db")
# allocations <-dbReadTable(pool, "contacts")
# dbDisconnect(pool)
# dbListFields(pool, "jabs_master")
# poolClose(pool)


haiti <- read_xlsx("21-02-09_2015_Haiti_Baptiste.xlsx", skip = 3) %>% select(1:6) %>% rename(change_BT = "Δ BT")
# haiti$Time2 %>% typeof()
haiti <- haiti %>% mutate(Time2 = lubridate::ms(Time2), Time1 = lubridate::ms(Time1))

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


# Note: pool cannot use dbSendQuery
loadData <- function(fields,
                     table,
                     WhereCls = '') {
  # Construct the fetching query
  if (WhereCls == '') {
    dataDB <- pool %>% tbl(table) %>% select(all_of(fields))
  }
  else {
    # dataDB <- pool %>% tbl(table) %>% filter(Org_Name == WhereCls)
  }
}
#     coffee_producting_countries selected_unique_key - selected_country    get_unique_key-get_country
coffee_producting_countries <-
c('Angola','Bolivia','Brazil','Burundi','Cameroon','Central African Republic',
'China','Colombia','Costa Rica','Cuba','Democratic Rep. of the Congo','Dominican Republic',
'Ecuador','El Salvador','Ethiopia','Gabon','Ghana','Guatemala','Guinea','Haiti','Honduras','India',
'Indonesia','Ivory Coast','Jamaica','Kenya','Laos','Liberia','Madagascar','Malawi','Mexico','Nicaragua',
'Nigeria','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Rwanda','Sierra Leone','Tanzania',
'Thailand','Timor Leste','Togo','Trinidad and Tobago','Uganda','Venezuela','Vietnam','Yemen','Zambia','Zimbabwe', 'Other')

coffee_roasting_machines <- c("SR500", "SR540", "SR800")
processing_methods <- c("Washed", "Natural/Dry", "Pulped Natural", "Honey", "Semi-Washed/Wet-Hulled")
coffee_varieties_arabica <- c("Typica", "Bourbon", "Mundo Novo", "Caturra", "Catuai", "Maragogype",
                      "SL-28", "SL-34", "Geisha", "Pacas", "Villa Sarchi", "Pacamara", "Kent", "S795")
