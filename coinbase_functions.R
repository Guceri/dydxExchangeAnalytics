library(rgdax)
source("_inputs.R")

last_trade_ETH <- function () {
  last_trade_ETH <- as.numeric(tail(public_trades(product_id = "ETH-USD")[3],n=1)[1,1])
  last_trade_ETH
}

last_trade_DAI <- function () {
  last_trade_DAI <- tail(public_trades(product_id = "DAI-USDC")[3],n=1)[1,1]
  last_trade_DAI
}

eth_dai <- function () {
  last_trade_ETH <- tail(public_trades(product_id = "ETH-USD")[3],n=1)[1,1]
  last_trade_DAI <- tail(public_trades(product_id = "DAI-USDC")[3],n=1)[1,1]
  last <- last_trade_ETH/last_trade_DAI
  last
}

btc_usd <- function () {
  last_trade_BTC <- tail(public_trades(product_id = "BTC-USD")[3],n=1)[1,1]
  last_trade_BTC
}


curr_bal_usd <- function(){
  #stays local to function
  error<-FALSE
  balance <- tryCatch({accounts(api.key = my_api.key, secret = my_secret, passphrase = my_passphrase)},error = function (e){
    error<<-TRUE
  })
  if(error){
    balance<-NULL
    return(balance)
  }else{
    #
    balance <- subset(balance$balance, balance$currency == "USD")
    return(balance)
  }
}

curr_bal_eth <- function(){
  error<-FALSE
  balance <- tryCatch({accounts(api.key = my_api.key, secret = my_secret, passphrase = my_passphrase)},error = function (e){
    error<<-TRUE
  })
  if(error){
    balance<-NULL
    return(balance)
  }else{
    balance <- subset(balance$balance, balance$currency == substr("ETH-USD",1,3))
    return(balance)
  }
}
