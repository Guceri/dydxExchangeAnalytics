#search for positins that will be expiring based on size of expirable position
rm(list=ls())

library(jsonlite)
library(dplyr)

source('coinbase_functions.R')

# min usd eqivalent that would be expiring (absolute value)
min_exp_size <- 10000
last_price <- last_trade_ETH()

#=============================RAW DATA=======================
dydx <- 'https://api.dydx.exchange/v1/accounts'
dydx <- fromJSON(dydx)
dydx_positions <- as.data.frame(dydx$accounts)
#=============================FILTERS========================
#filter account to ensure there is at least a position in either ETH, DAI or USDC
dydx_positions <- filter(dydx_positions,dydx_positions$balances$`0`$wei != "0" | dydx_positions$balances$`1`$wei != "0" | dydx_positions$balances$`2`$wei != "0" | dydx_positions$balances$`3`$wei != "0")
#=============================
owner <- as.data.frame(dydx_positions$owner)
account <- as.data.frame(dydx_positions$number)
eth <- as.data.frame(dydx_positions$balances$`0`$wei)
exp_eth <- as.data.frame(dydx_positions$balances$`0`$expiresAt)
exp_usdc <- as.data.frame(dydx_positions$balances$`2`$expiresAt)
exp_dai <- as.data.frame(dydx_positions$balances$`3`$expiresAt)
usdc <- as.data.frame(dydx_positions$balances$`2`$wei)
dai <- as.data.frame(dydx_positions$balances$`3`$wei)
#=============================
dydx_network <- bind_cols(owner,account,eth,dai,usdc,exp_eth,exp_dai,exp_usdc)
names <- c("owner","account","eth","dai","usdc","expiration_eth","expiration_dai","expiration_usdc")
colnames(dydx_network) <- names
#clean up variables for debugging
rm(dydx,account,dai,eth,owner,usdc,names,exp_eth,exp_dai,exp_usdc)
#convert positions to numeric 
dydx_network$eth <- round(as.numeric(as.character(dydx_network$eth))/10^18,2)
dydx_network$dai <- round(as.numeric(as.character(dydx_network$dai))/10^18,0)
dydx_network$usdc <- round(as.numeric(as.character(dydx_network$usdc))/10^6,0)
#=============================
#filter out any accounts that are not expirable for any currency
dydx_network_expirable <- subset(dydx_network,dydx_network$expiration_eth != "NA" | dydx_network$expiration_dai != "NA" | dydx_network$expiration_usdc != "NA" )
#filter out old expirations that are not relavent
dydx_network_expirable <- subset(dydx_network_expirable, as.Date(substr(dydx_network_expirable$expiration_eth,1,10)) > Sys.Date() | 
                                                         as.Date(substr(dydx_network_expirable$expiration_dai,1,10)) > Sys.Date() |
                                                         as.Date(substr(dydx_network_expirable$expiration_usdc,1,10)) > Sys.Date() )
#parse out each currency 
expiring_eth <- select(subset(dydx_network_expirable,dydx_network_expirable$expiration_eth != "NA"),-7,-8)
expiring_dai <- select(subset(dydx_network_expirable,dydx_network_expirable$expiration_dai != "NA"),-6,-8)
expiring_usdc <- select(subset(dydx_network_expirable,dydx_network_expirable$expiration_usdc != "NA"),-6,-7)

#parse out min sizing
expiring_eth <- (subset(expiring_eth,last_price*expiring_eth$eth > min_exp_size | last_price*expiring_eth$eth < -min_exp_size ))
expiring_dai <- (subset(expiring_dai,expiring_dai$dai > min_exp_size | expiring_dai$dai < -min_exp_size ))
expiring_usdc <- (subset(expiring_usdc,expiring_usdc$usdc > min_exp_size | expiring_usdc$usdc < -min_exp_size ))

rm(dydx_positions,dydx_network,dydx_network_expirable,last_price,min_exp_size,my_api.key,my_passphrase,my_secret,myAPIkey,myEmail,Pushbullet,
   btc_usd,curr_bal_eth,curr_bal_usd,eth_dai,last_trade_DAI,last_trade_ETH)
