#Compase Coinbase market vs dydx market in eth/dai
#alert user if trading outside dydx bid/ask and provide depth of edge

rm(list=ls())

library(httr)
library(jsonlite)
library(rgdax)
library(RPushbullet)
library(dplyr)

source('_inputs.R')

#===========================================================================================
#                                   GDAX
#===========================================================================================
eth_dai <- function () {
  last_trade_ETH <- tail(public_trades(product_id = "ETH-USD")[3],n=1)[1,1]
  last_trade_DAI <- tail(public_trades(product_id = "DAI-USDC")[3],n=1)[1,1]
  last <- last_trade_ETH/last_trade_DAI
  last
}
gdax_last <- round(eth_dai(),2)
#===========================================================================================
#                                   DYDX
#===========================================================================================
market <- GET("https://api.oasisdex.com/v2/orders/eth/dai")
market <- content(market,as="parsed")
dydx_bid <- round(as.numeric(market$data$bids[1][[1]][[1]]),2)
dydx_ask <- round(as.numeric(market$data$asks[1][[1]][[1]]),2)
#===========================================================================================
#                             EDGE PRICE & QTY
#===========================================================================================
if (gdax_last > dydx_ask){
  x<-1
  size <- vector()
  price <- vector()
  dydx_ask_orderbook <- dydx_ask
  while (dydx_ask_orderbook < gdax_last){
    price <- append(price,round(as.numeric(market$data$asks[x][[1]][[1]]),2))
    size <- append(size,round(as.numeric(market$data$asks[x][[1]][[2]]),2))
    x <- x + 1
    dydx_ask_orderbook <- round(as.numeric(market$data$asks[x][[1]][[1]]),2)
  }
  orderbook <- as.data.frame(cbind(price,size))
  orderbook <- mutate(orderbook,value=orderbook$price*orderbook$size)
  qty <- sum(orderbook$size)
  total_value <- sum(orderbook$value)
  ave_price <- round(total_value/qty,2)
  edge <- abs(round(ave_price-gdax_last,2))
  qty<-floor(qty)
  rm(orderbook,price,size,total_value,x,dydx_ask_orderbook)
  pbPost(type = 'note', title = paste0("Buy ", qty," contracts for ",edge," in edge"), email = myEmail, apikey = myAPIkey)
}

if (gdax_last < dydx_bid){
  x<-1
  size <- vector()
  price <- vector()
  dydx_bid_orderbook <- dydx_bid
  while (dydx_bid_orderbook > (gdax_last)){
    price <- append(price,round(as.numeric(market$data$bids[x][[1]][[1]]),2))
    size <- append(size,round(as.numeric(market$data$bids[x][[1]][[2]]),2)) 
    x <- x + 1
    dydx_bid_orderbook <- round(as.numeric(market$data$bids[x][[1]][[1]]),2)
  }
  orderbook <- as.data.frame(cbind(price,size))
  orderbook <- mutate(orderbook,value=orderbook$price*orderbook$size)
  qty <- sum(orderbook$size)
  total_value <- sum(orderbook$value)
  ave_price <- round(total_value/qty,2)
  edge <- abs(round(ave_price-gdax_last,2))
  qty<-floor(qty)
  rm(orderbook,price,size,total_value,x,dydx_bid_orderbook)
  pbPost(type = 'note', title = paste0("Sell ", qty," contracts for ",edge," in edge"), email = myEmail, apikey = myAPIkey)
}

rm(market,my_api.key,my_passphrase,my_secret,myAPIkey,myEmail,eth_dai,Pushbullet)