library(tidyverse)
library(ggplot2)
library(shiny)
library(shinydashboard)
library(ggplot2) # visualisation
library(scales) # visualisation
library(grid) # visualisation
library(RColorBrewer) # visualisation
library(corrplot) # visualisation
library(alluvial) # visualisation
library(dplyr) # data manipulation
library(readr) # input/output
library(data.table) # data manipulation
library(tibble) # data wrangling
library(tidyr) # data wrangling
library(stringr) # string manipulation
library(forcats) # factor manipulation
library(lubridate) # date and time
library(geosphere) # geospatial locations
library(leaflet) # maps
library(leaflet.extras) # maps
library(maps) # maps
library(bookdown)
library(shinythemes)

# read data
train <- as_tibble(fread("data/train.csv"))
test <- as_tibble(fread("data/test.csv"))
sample_submit <- as_tibble(fread("data/sample_submission.csv"))

## combine train and test
combine <- bind_rows(train %>% mutate(dset = "train"), 
                     test %>% mutate(dset = "test",
                                     dropoff_datetime = NA,
                                     trip_duration = NA))
combine <- combine %>% mutate(dset = factor(dset))

## reformating features
train <- train %>%
  mutate(pickup_datetime = ymd_hms(pickup_datetime),
         dropoff_datetime = ymd_hms(dropoff_datetime),
         vendor_id = factor(vendor_id),
         passenger_count = factor(passenger_count))


# define the ui interface
header <- dashboardHeader(title = "Taxi Duration Analysis of NYC",
                          
                          dropdownMenu(type = "messages",
                                       messageItem(
                                         from = "Extreme trip",
                                         message = "longer trip happens in JFK airport.",
                                         icon = icon("plane")
                                       ),
                                       messageItem(
                                         from = "Contact",
                                         message = "Need help or contact developer?",
                                         icon = icon("envelope"),
                                         href = "mailto:yzha0633@student.monash.edu"
                                       ),
                                       messageItem(
                                         from = "Support",
                                         message = "This app will continue to be updated.",
                                         icon = icon("github"),
                                         time = "2020-11-10",
                                         href = "https://github.com/Yiwen-Zhang-259/FIT5147-shiny-visualization"
                                       )
                                      ),
                          
                         dropdownMenu(type = "notifications",
                                      notificationItem(
                                         text = "7 new users today",
                                         icon = icon("users")
                                       ),
                                      notificationItem(
                                         text = "330 24-hour trips recorded",
                                         icon = icon("taxi"),
                                         status = "success"
                                       ),
                                      notificationItem(
                                         text = "Server load at 99%",
                                         icon = icon("exclamation-triangle"),
                                         status = "warning"
                                       )
                                      ))  

sidebar <- dashboardSidebar()

body <- dashboardBody()

ui <- dashboardPage(header, sidebar, body)


#define the server interface
server <- function(input, output) {
  
  output$messageMenu <- renderMenu({
    # Code to generate each of the messageItems here, in a list. This assumes
    # that messageData is a data frame with two columns, 'from' and 'message'.
    msgs <- apply(messageData, 1, function(row) {
      messageItem(from = row[["from"]], message = row[["message"]])
    })
    
    # This is equivalent to calling:
    #   dropdownMenu(type="messages", msgs[[1]], msgs[[2]], ...)
    dropdownMenu(type = "messages", .list = msgs)
  })
  
}


# Run the application
shinyApp(ui = ui, server = server)

