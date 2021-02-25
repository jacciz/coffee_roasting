library(tidyverse)    # includes tidyr, tibble, and more
library(lubridate)    # for working with dates, need this for data import
library(readxl)
library(RSQLite)
library(pool)
# Remote file servers: https://rpubs.com/berdaniera/shinyshop-remotedata

# ------------------------- Create database connection to SQLite database --------------------------------------

pool <- pool::dbPool(RSQLite::SQLite(), dbname = "data/roasting_profiles.db")
# pool <- dbPool(RSQLite::SQLite(), dbname = "C:/W_shortcut/vaccine_distribution/data/vaccine_inventory.db") # TEST LINK
# NON Pool
# pool <- dbConnect(RSQLite::SQLite(), dbname = "data/vaccine_inventory.db")
# pool <- dbConnect(RSQLite::SQLite(), dbname = "C:/W_shortcut/vaccine_distribution/data/vaccine_inventory.db")
# allocations <-dbReadTable(pool, "contacts")
# dbDisconnect(pool)
# dbListFields(pool, "jabs_master")
# poolClose(pool)

# ------------------------- Get data --------------------------------------
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
coffee_cupping_tasting = readxl::read_xlsx('data/coffee-flavors_lexicon.xlsx')
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

# ------------------------- Data for dropdown menus --------------------------------------

#     coffee_producting_countries selected_unique_key - selected_country    get_unique_key-get_country
units_of_measures <- c("grams", "ounces")
coffee_producting_countries <-
c('Angola','Bolivia','Brazil','Burundi','Cameroon','Central African Republic',
'China','Colombia','Costa Rica','Cuba','Democratic Rep. of the Congo','Dominican Republic',
'Ecuador','El Salvador','Ethiopia','Gabon','Ghana','Guatemala','Guinea','Haiti','Honduras','India',
'Indonesia','Ivory Coast','Jamaica','Kenya','Laos','Liberia','Madagascar','Malawi','Mexico','Nicaragua',
'Nigeria','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Rwanda','Sierra Leone','Tanzania',
'Thailand','Timor Leste','Togo','Trinidad and Tobago','Uganda','Venezuela','Vietnam','Yemen','Zambia','Zimbabwe', 'Other')

coffee_roasting_machines <- c("SR500", "SR540", "SR700", "SR800")
processing_methods <- c("Anaerobic Fermentation","Honey", "Natural/Dry", "Pulped Natural", "Semi-Washed/Wet-Hulled", "Washed")
coffee_varieties_arabica <- c("Typica", "Bourbon", "Mundo Novo", "Caturra", "Catuai", "Maragogype",
                      "SL-28", "SL-34", "Geisha", "Pacas", "Villa Sarchi", "Pacamara", "Kent", "S795")

# test <- "C:/W_shortcut/coffee_roasting/data/21-02-17_1840_ZambiaKasama_1stcrack.alog"
# x <- open_profile_as_json(test)
# js <- jsonlite::fromJSON(x)
# save <- "C:/W_shortcut/coffee_roasting/roast_profiles_json/country-region-2021-02-17-18-40-18.json"
# read_json <- profile

# This opens the .alog file that was opened, reads it, returns string
open_profile_as_json <-
  function(alog_input) {
    # Reads and puts it in a long string
    sub <- readLines(alog_input)
    # incomplete final line found on (c..) - could be bc you need to add line at end of json
    # Must replace ' and change True/False so it has quotes in order to read as a JSON
    sub <- gsub("\\'", '"', sub)
    sub <- gsub("True", '\"True\"', sub)
    sub <- gsub("False", '\"False\"', sub)
    sub
  }


# Creates a filename based on profile, returns  with location where it is saved (i.e. data/filename.json)
get_profile_filename <- function(profile_as_json, country, region) {
  # Create filename based on roast date, country and region
  # Using date and roast time to ensure a unique filename
  sprintf(
    "%s%s-%s-%s-%s.json",
    "roast_profiles_json/",
    # location to save
    country,
    region,
    profile_as_json$roastisodate,
    gsub(":", "-", profile_as_json$roasttime)
  )
}


# save_profile_as_json <- function(read_json, country, region) {
# 
#   write(read_json, filename)
#   # Need to get the entire filename and make a list so we can append to all_inputs_to_save
#   # save_filename <- c("filename" = filename) %>% as.list()
#   return(filename)
# }
