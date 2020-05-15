#input account below to see position and leverage details

rm(list=ls())

library(jsonlite)
library(dplyr)
library(rgdax)

source('_inputs.R')

whale_account <- '0x4a40e91175fa2f7dd8ae444596c7f5c98c4eac8b'

#============================================================================
#pull json file from api 
whale <- paste0('https://api.dydx.exchange/v1/accounts/',whale_account)
whale_JSON <- fromJSON(whale)

#account balances for ETH, DAI & USDC
accounts <- as.data.frame(whale_JSON$accounts$balances)

#filter for only positions; pulls par, wei and expiration for each currency
eth_positions <- accounts[,1]
usdc_positions <-accounts[,3]
dai_positions <- accounts[,4]

#adjust par/wei values to readable notation
eth_positions$wei <- as.numeric(eth_positions$wei)/10^18
dai_positions$wei <- as.numeric(dai_positions$wei)/10^18
usdc_positions$wei <- as.numeric(usdc_positions$wei)/10^6
#============================================================================
#Prices from GDAX
last_trade_ETH <- tail(public_trades(product_id = "ETH-USD")[3],n=1)[1,1]
last_trade_DAI <- round(tail(public_trades(product_id = "DAI-USDC")[3],n=1)[1,1],3)
#============================================================================
#sum all open positions for the specific account
dai_balance <- round(sum(dai_positions$wei),2)
eth_balance <- round(sum(eth_positions$wei),2)
usdc_balance <- round(sum(usdc_positions$wei),2)

#dollar balance held
eth_dollar_balance <- round(eth_balance*last_trade_ETH,2)
dai_dollar_balance <- round(dai_balance*last_trade_DAI,2)
usdc_dollar_balance <- round(usdc_balance,2)

if (dai_dollar_balance > 0){
  neg_dai_bal <- 0
  pos_dai_bal <- dai_dollar_balance
}else if (dai_dollar_balance < 0){
  neg_dai_bal <- dai_dollar_balance
  pos_dai_bal <- 0
} else{
  neg_dai_bal <- 0
  pos_dai_bal <- 0
  }

if (eth_dollar_balance > 0){
  neg_eth_bal <- 0
  pos_eth_bal <- eth_dollar_balance
}else if (eth_dollar_balance < 0){
  neg_eth_bal <- eth_dollar_balance
  pos_eth_bal <- 0
} else{
  neg_eth_bal <- 0
  pos_eth_bal <- 0
}

if (usdc_dollar_balance > 0){
  neg_usdc_bal <- 0
  pos_usdc_bal <- usdc_dollar_balance
}else if (usdc_dollar_balance < 0){
  neg_usdc_bal <- usdc_dollar_balance
  pos_usdc_bal <- 0
} else{
  neg_usdc_bal <- 0
  pos_usdc_bal <- 0
}

account_balances <- c(eth_dollar_balance,dai_dollar_balance,usdc_dollar_balance)
account_equity <- sum(account_balances)

pos_equity <- sum(account_balances[account_balances>0])
neg_equity <- sum(account_balances[account_balances<0])

#leverage
leverage <- round(eth_dollar_balance/account_equity,2)

#Collateral Ratio
col_ratio <- abs(round(pos_equity/neg_equity,2))
if(is.infinite(col_ratio)){col_ratio <- 0}

#liquidation price
if (eth_balance > 0 & col_ratio != 0){
  price_change <- -((1.15*abs(neg_dai_bal+neg_usdc_bal+neg_eth_bal)-pos_eth_bal-pos_dai_bal-pos_usdc_bal)/-eth_balance)
  } else 
  if (eth_balance < 0 & col_ratio != 0){
    price_change <- -((pos_dai_bal+pos_usdc_bal)/1.15+neg_eth_bal+neg_dai_bal+neg_usdc_bal)/eth_balance
  }else{
    price_change <- NA
  }

if (!is.na(price_change)){
  liquidation_price <- round(last_trade_ETH + price_change,2)
}

#Cleanup
rm(accounts,dai_positions,eth_positions,usdc_positions,whale_JSON,account_balances,dai_dollar_balance,eth_dollar_balance,my_api.key,my_passphrase,my_secret,
   neg_equity,pos_equity,usdc_dollar_balance,whale,neg_dai_bal,neg_eth_bal,neg_usdc_bal,pos_dai_bal,pos_eth_bal,pos_usdc_bal,price_change,myAPIkey,myEmail,Pushbullet)

















