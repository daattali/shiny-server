library(shiny)
library(dplyr)
library(ggplot2)

# YOU CAN IGNORE THIS: metadata for when sharing the app on facebook/twitter
share <- list(
  title = "BC Liquor Store prices",
  url = "http://daattali.com/shiny/bcl/",
  image = "http://daattali.com/shiny/img/bcl.png",
  description = "Had a long day? This app will help you find the right drink for tonight!",
  twitter_user = "daattali"
)

# load the data (retrieve and clean raw data if this is the first time)
filename <- file.path("data", "bcl-data.csv")
if (file.exists(filename)) {
  bcl <- read.csv(filename, stringsAsFactors = FALSE)
} else {
  bcl <- read.csv("http://pub.data.gov.bc.ca/datasets/176284/BC_Liquor_Store_Product_Price_List.csv",
                  stringsAsFactors = FALSE)
  products <- c("BEER", "REFRESHMENT BEVERAGE", "SPIRITS", "WINE")
  bcl <- dplyr::filter(bcl, PRODUCT_CLASS_NAME %in% products) %>%
    dplyr::select(-PRODUCT_TYPE_NAME, -PRODUCT_SKU_NO, -PRODUCT_BASE_UPC_NO,
                  -PRODUCT_LITRES_PER_CONTAINER, -PRD_CONTAINER_PER_SELL_UNIT,
                  -PRODUCT_SUB_CLASS_NAME) %>%
    rename(Type = PRODUCT_CLASS_NAME,
           Subtype = PRODUCT_MINOR_CLASS_NAME,
           Name = PRODUCT_LONG_NAME,
           Country = PRODUCT_COUNTRY_ORIGIN_NAME,
           Alcohol_Content = PRODUCT_ALCOHOL_PERCENT,
           Price = CURRENT_DISPLAY_PRICE,
           Sweetness = SWEETNESS_CODE)
  bcl$Type <- sub("^REFRESHMENT BEVERAGE$", "REFRESHMENT", bcl$Type)
  dir.create("data", showWarnings = FALSE)
  write.csv(bcl, filename, row.names = FALSE)
}

ui <- fluidPage(
  shinydisconnect::disconnectMessage2(),
  # Ignore this tags$head section, just adding metadata for facebook/twitter sharing
  tags$head(
    tags$link(rel = "shortcut icon", type="image/x-icon", href="http://daattali.com/shiny/img/favicon.ico"),
    # Facebook OpenGraph tags
    tags$meta(property = "og:title", content = share$title),
    tags$meta(property = "og:type", content = "website"),
    tags$meta(property = "og:url", content = share$url),
    tags$meta(property = "og:image", content = share$image),
    tags$meta(property = "og:description", content = share$description),
    
    # Twitter summary cards
    tags$meta(name = "twitter:card", content = "summary"),
    tags$meta(name = "twitter:site", content = paste0("@", share$twitter_user)),
    tags$meta(name = "twitter:creator", content = paste0("@", share$twitter_user)),
    tags$meta(name = "twitter:title", content = share$title),
    tags$meta(name = "twitter:description", content = share$description),
    tags$meta(name = "twitter:image", content = share$image)
  ),
  titlePanel("BC Liquor Store prices"),
  sidebarLayout(
    sidebarPanel(
      h4(
        "Had a long day?  This app will help you find the right drink for tonight! Just use the filters below..."
      ),
      br(),
      sliderInput("priceInput", "Price", 0, 100, c(25, 40), pre = "$"),
      uiOutput("typeSelectOutput"),
      checkboxInput("filterCountry", "Filter by country", FALSE),
      conditionalPanel(
        condition = "input.filterCountry",
        uiOutput("countrySelectorOutput")
      ),
      hr(),
      span("Data source:", 
        tags$a("OpenDataBC",
             href = "https://www.opendatabc.ca/dataset/bc-liquor-store-product-price-list-current-prices")),
      br(),
      span("Learn how to build this app", a(href = "http://deanattali.com/blog/building-shiny-apps-tutorial/", "with my Shiny tutorial")),
      br(), br(),
      em(
        span("Created by", a(href = "http://deanattali.com", "Dean Attali")),
        HTML("&bull;"),
        span("Code", a(href = "https://github.com/daattali/shiny-server/tree/master/bcl", "on GitHub"))
      )
    ),
    mainPanel(
      h3(textOutput("summaryText")),
      downloadButton("download", "Download results"),
      br(),
      plotOutput("plot"),
      br(), br(),
      #tableOutput("prices")
      DT::dataTableOutput("prices")
    )
  )
)

server <- function(input, output, session) {
  output$countrySelectorOutput <- renderUI({
    selectInput("countryInput", "Country",
                sort(unique(bcl$Country)),
                selected = "CANADA")
  })
  
  output$typeSelectOutput <- renderUI({
    selectInput("typeInput", "Product type",
                sort(unique(bcl$Type)),
                multiple = TRUE,
                selected = c("BEER", "WINE"))
  })
  
  output$summaryText <- renderText({
    numOptions <- nrow(prices())
    if (is.null(numOptions)) {
      numOptions <- 0
    }
    paste0("We found ", numOptions, " options for you")
  })
  
  prices <- reactive({
    prices <- bcl
    
    if (is.null(input$countryInput)) {
      return(NULL)
    }
    
    prices <- dplyr::filter(prices, Type %in% input$typeInput)
    if (input$filterCountry) {
      prices <- dplyr::filter(prices, Country == input$countryInput)
    }
    prices <- dplyr::filter(prices, Price >= input$priceInput[1],
                            Price <= input$priceInput[2])
    
    if(nrow(prices) == 0) {
      return(NULL)
    }
    prices
  })
  
  output$plot <- renderPlot({
    if (is.null(prices())) {
      return(NULL)
    }
    
    ggplot(prices(), aes(Alcohol_Content, fill = Type)) +
      geom_histogram(colour = "black") +
      theme_classic(20)
  })
  
  output$prices <- DT::renderDataTable({
    prices()
  })
  
  output$download <- downloadHandler(
    filename = function() {
      "bcl-results.csv"
    },
    content = function(con) {
      write.csv(prices(), con)
    }
  )
}

shinyApp(ui = ui, server = server)
