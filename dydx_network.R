#network level details about positions, and utilization. 
#this should look identical to the markets tab of dydx
#there may be rounding errors since price is taken from coinbase for eth/dai market

rm(list=ls())
options(scipen = 50)

library(jsonlite)
library(dplyr)

source("coinbase_functions.R") #eth_dai() derived off of gdax price
#=============================RAW DATA=======================
dydx <- 'https://api.dydx.exchange/v1/accounts'
dydx <- fromJSON(dydx)
dydx_positions <- as.data.frame(dydx$accounts)
#=============================FILTERS========================
#filter account to ensure there is at least a position in either ETH, DAI or USDC
#seems to be orphaned but will leave in code just incase
dydx_positions <- filter(dydx_positions,dydx_positions$balances$`0`$wei != "0" | dydx_positions$balances$`1`$wei != "0" | dydx_positions$balances$`2`$wei != "0" | dydx_positions$balances$`3`$wei != "0")
#need to create a single layer data frame to work with; extract each useful column and then merge
owner <- as.data.frame(dydx_positions$owner)
account <- as.data.frame(dydx_positions$number)
eth <- as.data.frame(dydx_positions$balances$`0`$wei)
usdc <- as.data.frame(dydx_positions$balances$`2`$wei)
dai <- as.data.frame(dydx_positions$balances$`3`$wei)
dydx_network <- bind_cols(owner,account,eth,usdc,dai)
names <- c("owner","account","eth","usdc","dai")
colnames(dydx_network) <- names
#convert positions to numeric 
dydx_network$eth <- round(as.numeric(as.character(dydx_network$eth))/10^18,2)
dydx_network$usdc<- round(as.numeric(as.character(dydx_network$usdc))/10^6,0)
dydx_network$dai <- round(as.numeric(as.character(dydx_network$dai))/10^18,0)
#==========================NETWORK STATS===============================
#Position related stats
eth_positions <- sum(dydx_network$eth)
dai_positions <- sum(dydx_network$dai)
usdc_positions <- sum(dydx_network$usdc)
eth_dollars <- round(eth_positions*eth_dai(),2)
network_equity <- round(eth_dollars+dai_positions+usdc_positions,2)
network_leverage <- round(eth_dollars/network_equity,2)
#Rates related stats
#==========================================================
eth_borrowed <- abs(sum(dydx_network$eth[dydx_network$eth<0]))
eth_supplied <- sum(dydx_network$eth[dydx_network$eth>0])
dai_borrowed <- abs(sum(dydx_network$dai[dydx_network$dai<0]))
dai_supplied <- sum(dydx_network$dai[dydx_network$dai>0])
usdc_borrowed <- abs(sum(dydx_network$usdc[dydx_network$usdc<0]))
usdc_supplied <- sum(dydx_network$usdc[dydx_network$usdc>0])
eth_utilization <- round(eth_borrowed/eth_supplied,4)
dai_utilization <- round(dai_borrowed/dai_supplied,4)
usdc_utilization <- round(usdc_borrowed/usdc_supplied,4)
#MISC
#==========================================================
#number of unique accounts 
num_accounts <- length(unique(dydx_network$owner))
#CLEANUP
#==========================================================
rm(account,dai,dydx,dydx_network,dydx_positions,eth,owner,usdc,my_api.key,my_passphrase,my_secret,names,btc_usd,curr_bal_eth,curr_bal_usd,eth_dai,Pushbullet,
   myAPIkey,myEmail,last_trade_DAI,last_trade_ETH)