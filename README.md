# Shiny dashboard : Analysis on Taxi Duration in NYC


### Creator & Author : Yiwen Zhang

This is the shiny dashborad for analysis on taxi duration in NYC, hope you can enjoy your exlporation.
And if there is any error, please feel free to write a github issue. 

Thank you and have fun !

## User guide

### Installation of packages

```r
install.packages(c(“tidyverse”, “plotly”, “shiny”, “shinydashboard”, “ggplot2”, “scales”, “grid”, “corrplot”, “alluvial”, “dplyr”, “readr”, “data.table”, “tibble”, “tidyr”, “stringr”, “forcats”, “lubridate”, “geosphere”, “leaflet”, “maps”, “shinythemes”, “bookdown”))
```
_It should be noted that in order to make “wday” function work normally, please load package **data.table** first and then load package **lubridate**_ :)

### Launch the app

``` r
Run App
```

### Shiny Application User Interface

#### Main page

Once you have launched this app, it comes to the main page as below.

<img src="man/figures/shiny.png" alt="logo" width="250"/>


You can click the dropdown menus to get contact with creator by email or get support from Gihub. Also, you can zoom in or zoom out to view this distribution map in detail.

<img src="man/figures/shiny1.png" alt="logo" width="300"/>   <img src="man/figures/shiny2.png" alt="logo" width="300"/>

And if you want to hide the navigation bar, please just click the button in header, just next to the title.

<img src="man/figures/shiny3.png" alt="logo"/>

#### Subpage 1 point plot

<img src="man/figures/shiny4.png" alt="logo" width="250"/>
