library(tidyverse)
library(ggplot2)
library(plotly)
library(shiny)
library(shinydashboard)
library(ggplot2) # visualisation
library(scales) # visualisation
library(grid) # visualisation
library(dplyr) # data manipulation
library(readr) # input/output
library(tibble) # data wrangling
library(tidyr) # data wrangling
library(stringr) # string manipulation
library(forcats) # factor manipulation
library(lubridate) # date and time
library(leaflet) # maps
library(ggplot2)
library(tidyverse)
library(shinythemes)
Sys.setlocale("LC_ALL","C")


# read data
train <- as_tibble(fread("data/train.csv"))
test <- as_tibble(fread("data/test.csv"))
sample_submit <- as_tibble(fread("data/sample_submission.csv"))


## reformating features
train <- train %>%
  mutate(pickup_datetime = ymd_hms(pickup_datetime),
         dropoff_datetime = ymd_hms(dropoff_datetime),
         vendor_id = factor(vendor_id),
         passenger_count = factor(passenger_count))

## compute the distance
pick_coord <- train %>%
  select(pickup_longitude, pickup_latitude)
drop_coord <- train %>%
  select(dropoff_longitude, dropoff_latitude)
train$dist <- distCosine(pick_coord, drop_coord)

## compute the speed
train4 <- train %>%
  mutate(speed = dist/trip_duration*3.6,
         date = date(pickup_datetime),
         month = month(pickup_datetime, label = TRUE),
         wday = wday(pickup_datetime, label = TRUE, week_start = 1),
         wday = fct_relevel(wday, c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
         hour = hour(pickup_datetime),
         work = (hour %in% seq(8,18)) & (wday %in% c("Mon","Tues","Wed","Thurs","Fri"))
  )  

## model data
model_data <- train4 %>%
  select(vendor_id, trip_duration, speed, wday, hour)

model_s <- sample_n(model_data, 3e3)

# map
foo <- sample_n(train, 8e3)



# define the ui interface
header <- dashboardHeader(title = "Taxi Duration Analysis of NYC",
                          titleWidth = 300,
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

sidebar <- dashboardSidebar(
  
  sidebarMenuOutput("menu"),
  sidebarMenu(
    menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Point plot", icon = icon("th"), tabName = "pointplot"),
    menuItem("Box plot", icon = icon("th-large"), tabName = "boxplot"),
    menuItem("Heat diagram", icon = icon("cubes"), tabName = "heatplot"),
    menuItem("About", icon = icon("accusoft"), tabName = "about"),
    menuItem("Instruction", icon = icon("lightbulb"), tabName = "instruction"),
    menuItem("Source code", icon = icon("file-code-o"), 
             href = "https://github.com/Yiwen-Zhang-259/FIT5147-shiny-visualization"
    ),
    sidebarSearchForm(textId = "searchText", buttonId = "searchButton",
                      label = "Search...")
  )
)

body <- dashboardBody(
  # Also add some custom CSS to make the title background area the same
  # color as the rest of the header.
  tags$head(tags$style(HTML('
        .skin-blue .main-header .logo {
          background-color: #3c8dbc;
        }
        .skin-blue .main-header .logo:hover {
          background-color: #3c8dbc;
        }
      '))),
  tabItems(
    tabItem(tabName = "dashboard",
            h2("Some interesting factors!"),
            fluidRow(
              # tatic valueBox
              valueBox("15.98 mins", "Average Duration", icon = icon("stopwatch")),
              valueBox(2.66, "Average Passenger Count", icon = icon("user-friends"),color = "purple"),
              valueBox("14.44 km/h", "Average Speed", icon = icon("tachometer-alt"), color = "orange"),

            ),
            fluidRow(
              box(
                title = "Taxi Business distribution in NYC",
                leafletOutput("map")),
              
              box(
                h4(strong("Brief Explanation"), style = 'font-size:20px'),
                "It can be seen that all the trips took place in NYC city, especially in Manhattan only.",
                tags$br(),
                "Users can manually zoom in or zoom out to view the distribition in detail.",
                tags$br(),
                tags$br(),
                 "There are two providers associated with the trip record, one is represented with vendor id '1', and another is vendor id '2'.",
                tags$br(),
                 "When you mouse over the purplr point, it will show which provider the record of the trip is from.",
                tags$br(),
                 "Hope you can enjoy your exploration in this APP",
                style = 'font-size:17px',
                side = "right",
                #width = 12
              )
            )
            
            
        ), 

    tabItem(tabName = "pointplot",
            h2("Median Duration in Day of the Week"),
            h3("vs in Hour of the Day"),
            fluidRow(
              column(
                title = "Median Duration in Day of the Week",
                box(
                  width = 6,
                  checkboxGroupInput("typeInput", "Providers",
                                     choices = c("Vendor ID : 1" = "1",
                                                 "Vendor ID : 2" = "2"),
                                     selected = c("Vendor ID : 2" = "2")),
                  
                  plotlyOutput("avg_duration")
                ),
                box(
                  width = 6,
                  side = "right",
                  plotlyOutput("avg_duration1")
                ),
               
                class = "duration",
                width = 12,
                style = 'padding:0px;'
              ),
              column(
                sliderInput(
                  "timeSlider",
                  label      = "Select date",
                  min        = min(train$pickup_datetime),
                  max        = max(train$pickup_datetime),
                  value      = max(train$pickup_datetime),
                  width      = "100%",
                  timeFormat = "%d.%m.%Y",
                  animate    = animationOptions(loop = TRUE)
                ),
                class = "slider",
                width = 12,
                style = 'padding-left:15px; padding-right:15px; font-size:20px'
              ),
             
             column(
              h4(strong("Brief Explanation"), style = 'font-size:20px'),
              "The bar graph shows the average taxi duration per day in a week.",
              tags$br(),
              "The line graph shows the average taxi duration per hour in one day.",
              tags$br(),
              "Users can manually click the button upside the bar graph to select the trip record provider.",
              tags$br(),
              "Users can select only one provider or two providers at the same time.",
              tags$br(),
              "Also, users can set the time range with the slider, and just click the triangle button,",
              tags$br(),
              "it will move on automatically!",
              tags$br(),
              tags$br(),
              "It can be observed that the taxi travels longer in weekdays and rush hour.",
              tags$br(),
              "And taxi trip from vendor 2 is higher than that of vendor 1.",
              style = 'font-size:17px',
              width = 12,
              # style = "padding: 15px"
            )
            )
    ),
    tabItem(tabName = "boxplot",
            h2("Median Duration vs Passenger Count"),
            fluidRow( 
              #box(
                #width = 8,
                column(
                  selectizeInput("passengerInput", "Passenger Count",
                                 choices = unique(train$passenger_count),
                                 selected= as.numeric("1"), multiple =FALSE), 
                  width = 4),
                
                column(
                  plotlyOutput("passenger"),
                  width = 8
                ),
              column(
                h4(strong("Brief Explanation"), style = 'font-size:20px'),
                "The box chart shows the average taxi duration under two vendors with different passenger counts.",
                tags$br(),
                "Users can manually select the number of passengers she or he is interested. By default, the passenger count '1' is chosen in the plots.",
                tags$br(),
                tags$br(),
                "It can be observed that the patterns in two vendors are very similar and little difference among durations under different passenger counts.",
                tags$br(),
                "Specially,long distance trips over 24 hours exist in vendor 1, while those with more than 7 passengers only exist in vendor 2.",
                style = 'font-size:17px',
                width = 12
                # style = "padding: 15px"
              )
             
            )
    ),
    tabItem(tabName = "heatplot",
            h2("How the speed change and influence the duration?"),
            fluidRow(
              column(
              width = 12,
              box(
                title = "Speed throughout the Day and Time",
                plotlyOutput("heat"),
                #height = 3,
              ),
                box(
                  title = "Correlation between Speed and Duration",
                  plotlyOutput("model"),
                  checkboxInput("modelInput", label = "Point Plot", value = FALSE)
        
                  #style = "float: right; padding: 10px; margin-right: 50px"
                )
              
              ),
              column(
                h4(strong("Brief Explanation"), style = 'font-size:20px'),
                "The heat diagarm shows the average speed per day and per hour.",
                tags$br(),
                "The regression curve shows how the speed influence the duration.",
                tags$br(),
                "Users can manually click the button beside the right-side graph to view the point plot.",
                tags$br(),
                tags$br(),
                "It can be observed that taxi travels faster on weekends and early morning.",
                tags$br(),
                "And with the increase of speed, taxi duration tends to decrease.",
                tags$br(),
                "However, at speeds between 20km/h and 40km/h, the duration also increases slightly.",
                style = 'font-size:17px',
                width = 8
                # style = "padding: 15px"
              )
            )
    ),
    tabItem(tabName = "about",
            fluidRow(
              fluidRow(
                column(
                  box(
                    title = div("About this Shiny App", style = "padding-left: 25px", class = "h2"),
                    column(
                      "This shiny app is about the analysis on taxi duration in New York City, and provides an overview of the taxi trip disbution in this city.
                       The 'shiny' package could display the interesting findings from previous analysis, which provide an concise way to build interactive web-based apps straight from R.
                       The code behind the dashboard available ",
                      tags$a(href = "https://github.com/Yiwen-Zhang-259/FIT5147-shiny-visualization", "here"),".
                       The findings are displayed in a map, figures, and plots.",
                      tags$br(),
                      h3("Motivations"),
                      "Taking a taxi is a way of travel that people often choose in daily life, and taxi has become a very important part of urban traffic. When taking a taxi, we are most concerned about the distance and fare. As we all know, the fare increases with the increase of the duration. So I can't help but wonder, apart from geographical factors (the distance between the origin place and the destination), what other factors will affect the taxi duration? So, in this app I will display my findings about this and answer my original research questions:",
                      tags$br(),
                      tags$br(),
                      "- How does the variation in trip numbers throughout the day and the week affect the average trip duration?",
                      tags$br(),
                      "- Whether different numbers of passengers and/or the different vendors are correlated with the duration of the trip?",
                      tags$br(),
                      "- How the day of the week and the time of the day affect the speed of the taxi?",
                      tags$br(),
                      tags$br(),
                      "Only look at the data, it is hard to interpret how the taxi duration changes throughout the day, and how do the passenger count as well as taxi speed influence the duration. Therefore, I developed this dashboard to visualize these interesting relations by providing several interactive plots. By exploring this dashboard, I hope it possible for you to get something inspired and have fun.",
                      tags$br(),
                      h3("Data Source"),
                      "The raw dataset is from",
                      tags$a(href = "https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page", "2016 NYC Yellow Cab trip record data"), ". Then it was sampled and cleaned by NYC Taxi and Limousine Commission.",
                      h3("Creator"),
                      "Yiwen Zhang | Master of Business Analystics student in Monash University @",
                      tags$a(href = "https://github.com/Yiwen-Zhang-259/FIT5147-shiny-visualization", "Yiwen Zhang's Github"),
                      h3("References"),
                      "Chang, Winston, and Barbara Borges Ribeiro. 2018. Shinydashboard: Create Dashboards with ’Shiny’. https://CRAN.R-project.org/package=shinydashboard.",
                      tags$br(),
                      tags$br(),
                      "Chang, Winston, Joe Cheng, JJ Allaire, Yihui Xie, and Jonathan McPherson. 2020. Shiny: Web Application Framework for R. https://CRAN.R-project.org/package=shiny.",
                      tags$br(),
                      tags$br(),
                      "Cheng, Joe, Bhaskar Karambelkar, and Yihui Xie. 2019. Leaflet: Create Interactive Web Maps with the Javascript ’Leaflet’ Library. https://CRAN.R-project.org/package=leaflet.",
                      tags$br(),
                      tags$br(),
                      "Chang, W. (2018, November 06). Themes for Shiny [R package shinythemes version 1.1.2]. Retrieved from https://CRAN.R-project.org/package=shinythemes.",
                      tags$br(),
                      tags$br(),
                      "Sievert, Carson. 2020. Interactive Web-Based Data Visualization with R, Plotly, and Shiny. Chapman; Hall/CRC. https://plotly-r.com.",
                      tags$br(),
                      tags$br(),
                      " R Core Team (2020). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria.URL https://www.R-project.org/. ",
                      tags$br(),
                      tags$br(),
                      "Wickham, Hadley. 2016. Ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York. https://ggplot2.tidyverse.org.",
                      tags$br(),
                      tags$br(),
                      "Wickham, Hadley, Mara Averick, Jennifer Bryan, Winston Chang, Lucy D’Agostino McGowan, Romain François, Garrett Grolemund, et al. 2019. “Welcome to the tidyverse.” Journal of Open Source Software 4 (43): 1686. https://doi.org/10.21105/joss.01686.",
                      tags$br(),
                      tags$br(),
                      "Wickham, Hadley, Romain François, Lionel Henry, and Kirill Müller. 2020. Dplyr: A Grammar of Data Manipulation. https://CRAN.R-project.org/package=dplyr.",
                      tags$br(),
                      tags$br(),
                      "Wickham, Hadley, and Dana Seidel. 2020. Scales: Scale Functions for Visualization. https://CRAN.R-project.org/package=scales.",
                      tags$br(),
                      tags$br(),
                      "Kirill M<U+00FC>ller and Hadley Wickham (2020). tibble: Simple Data Frames. R package version 3.0.4. https://CRAN.R-project.org/package=tibble.",
                      tags$br(),
                      tags$br(),
                      "Hadley Wickham (2019). stringr: Simple, Consistent Wrappers for Common String Operations. R package version 1.4.0. https://CRAN.R-project.org/package=stringr.",
                      tags$br(),
                      tags$br(),
                      "Hadley Wickham (2020). forcats: Tools for Working with Categorical Variables (Factors). R package version 0.5.0. https://CRAN.R-project.org/package=forcats.",
                      tags$br(),
                      tags$br(),
                      " Garrett Grolemund, Hadley Wickham (2011). Dates and Times Made Easy with lubridate. Journal of Statistical Software, 40(3), 1-25. URL http://www.jstatsoft.org/v40/i03/.",
                      width = 12,
                      style = "padding-left: 20px; padding-right: 20px; padding-bottom: 40px; margin-top: -15px"
                    ),
                    width = 12,
                  ),
                  width = 12,
                  style = "padding: 20px"
                )
              )
            )),
    
    tabItem(tabName = "instruction")
  
  )

)

ui <- dashboardPage(header, sidebar, body,skin = "black")


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
  
  output$menu <- renderMenu({
    sidebarMenu(
      menuItem("Menu item", icon = icon("calendar"))
    )
  })
  
  output$map <- renderLeaflet({
    
    set.seed(1234)
    marker_map <- "purple"
    
    leaflet() %>%
      #use setView() to choose the  map center and zoom level
      setView(lat = 40.74434, lng = -73.98105,  zoom = 11) %>%
      addProviderTiles("Stamen.Watercolor") %>%
      addCircleMarkers(
        data = foo,
        # set layer-Id to get id in click event
        #layerId = ~vendor_id, 
        lng = ~pickup_longitude,
        lat = ~pickup_latitude,
        radius = 1, 
        label = ~vendor_id, #  show label name when mouse hovers
        weight = 1,
        color = marker_map
      )
    
  })
  
output$avg_duration <- renderPlotly ({

  
 train1 <- train %>% filter(pickup_datetime <= input$timeSlider)%>% filter(vendor_id == input$typeInput)%>%
    mutate(wday = wday(pickup_datetime, label = TRUE, week_start = 1)) %>%
    group_by(wday, vendor_id) %>%
    summarise(median_duration = median(trip_duration)/60)
  
    ggplot(train1,aes(wday, median_duration, color = vendor_id)) +
    #geom_point(size = 4) +
    labs(x = "Day of the week", y = "Median trip duration [min]") +
    ggtitle("Median Duration in Day of the Week") +
    theme(#axis.title.x = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank())
  
  plot_ly(data = train1, x = ~wday,y = ~median_duration,type = "bar") %>%
    layout(
      yaxis = list(title = "Median trip duration"),
      xaxis = list(title = "Day of the week"))
     
  
})

output$avg_duration1 <- renderPlotly ({
  
  
  train2 <- train %>% filter(pickup_datetime <= input$timeSlider)%>% filter(vendor_id == input$typeInput)%>%
    mutate(hpick = hour(pickup_datetime)) %>%
    group_by(hpick, vendor_id) %>%
    summarise(median_duration = median(trip_duration)/60)
  
  ggplot(train2,aes(hpick, median_duration, color = vendor_id)) +
    geom_line(method = "loess", span = 1/2) +
    geom_point(size = 4) +
    labs(x = "Time of the day", y = "Median trip duration [min]") +
    theme(legend.position = "none") +
    theme_minimal()
 
})

output$passenger <- renderPlotly ({
  
  
  train3 <- train %>% filter(passenger_count == input$passengerInput)
  
    ggplot(train3,aes(vendor_id, trip_duration,color = vendor_id)) +
    geom_boxplot(width = 0.1) +
    scale_y_log10() +
    theme_minimal() +
    theme(legend.position = "none") +
    labs(y = "Trip duration [s]", x = "Number of passengers",fill = "vendor id" )
  
})

output$heat <- renderPlotly ({
  
  speed_data <- train4 %>%
    group_by(wday, hour) %>%
    summarise(median_speed = median(speed))
  
    ggplot(speed_data,aes(hour, wday, fill = median_speed)) +
    geom_tile() +
    labs(x = "Hour of the day", y = "Day of the week") +
    scale_fill_distiller(palette = "Spectral") +
    theme(#axis.title.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = "none")
   
   })



output$model <- renderPlotly ({
  

  
  p1<- model_s %>%
    ggplot(aes(speed,trip_duration)) +
    geom_point(size = 2,color = "orange") +
    theme_minimal() +
    #ggtitle("Correlation between Speed and Duration") +
    xlab("Speed [km/h]")+
    ylab("Trip Duration [s]")
  
  p2 <- model_s %>%
    ggplot(aes(speed,trip_duration)) +
    geom_smooth(method = "loess", span = 1/2)+
    theme_minimal() +
    #ggtitle("Speed Distribution by Day and Time") +
    xlab("Speed [km/h]")+
    ylab("Trip Duration [s]")
  
  
  if (input$modelInput) {
    p <- p1  }
    else {
    p <- p2
  }
  return(p)
  
 })


}


# Run the application
shinyApp(ui = ui, server = server)

