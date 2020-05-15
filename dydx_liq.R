rm(list=ls())
options(scipen = 50)

library(jsonlite)
library(dplyr)
library(DescTools) #RoundTo()
library(ggplot2)
library(ggpubr)
library(magrittr)

source("coinbase_functions.R") #eth_dai()
#=============================RAW DATA=======================
dydx <- 'https://api.dydx.exchange/v1/accounts'
markets <- 'https://api.dydx.exchange/v1/markets'
dydx <- fromJSON(dydx)
markets <- fromJSON(markets)
dydx_positions <- as.data.frame(dydx$accounts)
dydx_markets <- as.data.frame(markets$markets)
#=============================FILTERS========================
#filter account to ensure there is at least a position in either ETH, DAI or USDC
dydx_positions <- filter(dydx_positions,dydx_positions$balances$`0`$wei != "0" | dydx_positions$balances$`1`$wei != "0" | dydx_positions$balances$`2`$wei != "0")
#need to create a single layer data frame to work with; extract each useful column and then merge
owner <- as.data.frame(dydx_positions$owner)
account <- as.data.frame(dydx_positions$number)
eth <- as.data.frame(dydx_positions$balances$`0`$wei)
usdc <- as.data.frame(dydx_positions$balances$`2`$wei)
dai <- as.data.frame(dydx_positions$balances$`3`$wei)
dydx_network <- bind_cols(owner,account,eth,dai,usdc)
names <- c("owner","account","eth","dai","usdc")
colnames(dydx_network) <- names
#convert positions to numeric 
dydx_network$eth <- round(as.numeric(as.character(dydx_network$eth))/10^18,2)
dydx_network$dai <- round(as.numeric(as.character(dydx_network$dai))/10^18,0)
dydx_network$usdc <- round(as.numeric(as.character(dydx_network$usdc))/10^6,0)
#=============================PRICES========================
#DYDX PRICE FEED
#eth oracle price
eth_oracle_price <- round(as.numeric(as.character(dydx_markets$oraclePrice[1]))/10^18,2)
#usdc oracle price (always pegged to 1)
usdc_oracle_price <- 1
#dai oracle price
dai_oracle_price <- round(as.numeric(as.character(dydx_markets$oraclePrice[4]))/10^18,4)
#=========================BALANCES=========================
#dollar balance of ether held based on oracle price
eth_dollar_balance <- as.data.frame(round(dydx_network$eth*eth_oracle_price,2))
#dollar balance of dai held based on oracle price
dai_dollar_balance <- as.data.frame(round(dydx_network$dai*dai_oracle_price,0))
#dollar balance of usdc held based on oracle price
usdc_dollar_balance <- as.data.frame(round(dydx_network$usdc*usdc_oracle_price,0))
#=========================LEVERAGE=========================
#account balances
account_balances <- cbind(eth_dollar_balance,dai_dollar_balance,usdc_dollar_balance)
#account equity
account_equity <- as.data.frame(eth_dollar_balance+dai_dollar_balance+usdc_dollar_balance)
#leverage
leverage <- as.data.frame(round(eth_dollar_balance/account_equity,2))
leverage[is.na(leverage)]<-0
#=========================COL_RATIO========================
#copy balance to modify values
pos_eth_bal <- eth_dollar_balance
#zero out any negative value
pos_eth_bal[pos_eth_bal<0]<-0
#copy balance to modify values
neg_eth_bal <- eth_dollar_balance
#zero out any ps value
neg_eth_bal[neg_eth_bal>0]<-0
#Same thing for dai
pos_dai_bal <- dai_dollar_balance
pos_dai_bal[pos_dai_bal<0]<-0
neg_dai_bal <- dai_dollar_balance
neg_dai_bal[neg_dai_bal>0]<-0
#Same thing for usdc
pos_usdc_bal <- usdc_dollar_balance
pos_usdc_bal[pos_usdc_bal<0]<-0
neg_usdc_bal <- usdc_dollar_balance
neg_usdc_bal[neg_usdc_bal>0]<-0
#Summation of pos and neg balances
pos_balance <- pos_eth_bal + pos_dai_bal + pos_usdc_bal
neg_balance <- neg_eth_bal + neg_dai_bal + neg_usdc_bal
#Collateral Ratio
col_ratio <- abs(round(pos_balance/neg_balance,2))
#take out (NaN,Na,inf)
is.na(col_ratio)<-sapply(col_ratio, is.infinite)
col_ratio[is.na(col_ratio)]<-0
#if total leverage is less than one, ignore
col_ratio[abs(leverage) <= 1]<- 0
#merge columns
dydx_network_liq <- bind_cols(dydx_network,account_equity,leverage,col_ratio)
names(dydx_network_liq)[6:8] <- c("equity","leverage","col_ratio")
#========================PRICE CHANGE======================
#create empty data frame for loop below with the proper length
price_change <- data.frame()[1:nrow(dydx_network_liq),]
for (x in 1:nrow(dydx_network_liq)){
  #filter for position direction and if they are using margin
  if (dydx_network_liq$eth[x]>1 & dydx_network_liq$col_ratio[x] != 0){
    price_change[x,1] <- -((1.15*abs(neg_dai_bal[x,1]+neg_usdc_bal[x,1]+neg_eth_bal[x,1])-pos_eth_bal[x,1]-pos_dai_bal[x,1]-pos_usdc_bal[x,1])/-dydx_network$eth[x])
  } else 
  if (dydx_network_liq$eth[x]<(-1) & dydx_network_liq$col_ratio[x] != 0){
    price_change[x,1] <- -((pos_dai_bal[x,1]+pos_usdc_bal[x,1])/1.15+neg_eth_bal[x,1]+neg_dai_bal[x,1]+neg_usdc_bal[x,1])/dydx_network$eth[x]
  }else{
    price_change[x,1] <- NA
  }
}
#merge columns
dydx_network_liq <- bind_cols(dydx_network_liq,price_change)
names(dydx_network_liq)[9] <- "price_change"
#=====================FILTER ACCOUNTS======================
#Filter out all accounts smaller than $1000
dydx_network_liq <- filter(dydx_network_liq,dydx_network_liq$equity>1000)
#Filter any account with a col ratio > 2 (not leveraged enough)
dydx_network_liq <- filter(dydx_network_liq,dydx_network_liq$col_ratio<2)
#Filter any account that has no col_ratio (no liquidation potential)
dydx_network_liq <- filter(dydx_network_liq,dydx_network_liq$col_ratio!=0)
#filter out any trades that are further than $100 away from liquidation
dydx_network_liq <- filter(dydx_network_liq,abs(dydx_network_liq$price_change)<100)
#Add liq_price column
dydx_network_liq <- mutate(dydx_network_liq,liq_price=eth_oracle_price+dydx_network_liq$price_change)
#========================LIQUIDATION QTY===============================
liq_qty <- data.frame()[1:nrow(dydx_network_liq),]
for (x in 1:nrow(dydx_network_liq)){
  #dealing with leveraged long trades
  if (dydx_network_liq$eth[x]>0){
    if (dydx_network_liq$dai[x]<0 & dydx_network_liq$usdc[x]>=0){
      liq_qty[x,1] <- abs(dydx_network_liq$dai[x])/dydx_network_liq$liq_price[x]
    }else if (dydx_network_liq$dai[x]>=0 & dydx_network_liq$usdc[x]<0){
        liq_qty[x,1] <- abs(dydx_network_liq$usdc[x])/dydx_network_liq$liq_price[x]
    }else if (dydx_network_liq$dai[x]<0 & dydx_network_liq$usdc[x]<0){
      liq_qty[x,1] <- abs(dydx_network_liq$dai[x]+dydx_network_liq$usdc[x])/dydx_network_liq$liq_price[x]
    } else {liq_qty[x,1] <- 0}
  #dealing with leveraged short trades  
  }else if (dydx_network_liq$eth[x]<0){
    liq_qty[x,1] <- dydx_network_liq$eth[x]
  }else {liq_qty[x,1] <- 0}
}
dydx_network_liq <- bind_cols(dydx_network_liq,liq_qty)
names(dydx_network_liq)[11] <- "liq_qty"
#========================LIQUIDATION HIST==============================
#Short position liquidation prices
short_pos <- filter(dydx_network_liq,dydx_network_liq$eth<0)
#take out NA values
short_pos <- filter(short_pos,!is.na(short_pos$liq_price))
#bin liquidation values by $5 increments
short_pos$liq_price <- RoundTo(short_pos$liq_price,5)
#==========================================================
#Long position liquidation prices
long_pos <- filter(dydx_network_liq,dydx_network_liq$eth>0)
#take out NA values
long_pos <- filter(long_pos,!is.na(long_pos$liq_price))
#bin liquidation values by $5 increments
long_pos$liq_price <- RoundTo(long_pos$liq_price,5)
#==========================================================
#sum the amount that can be liquidated for each bin
long_pos_summary <- aggregate.data.frame(long_pos$liq_qty,by=list(long_pos$liq_price),FUN = sum)
names(long_pos_summary)[1:2] <- c("Liq_Price","Quantity")
short_pos_summary <- aggregate.data.frame(short_pos$liq_qty,by=list(short_pos$liq_price),FUN = sum)
names(short_pos_summary)[1:2] <- c("Liq_Price","Quantity")
pos_summary <- bind_rows(long_pos_summary,short_pos_summary)
#==========================================================
bar_chart <- ggplot(data = pos_summary, aes(x=Liq_Price,y=Quantity))+geom_bar(stat = "identity")+
  geom_vline(xintercept = eth_oracle_price)+
  geom_hline(yintercept = 0)+
  scale_x_continuous(breaks = seq(min(pos_summary$Liq_Price),max(pos_summary$Liq_Price),10))+
  scale_y_continuous(breaks = seq(RoundTo(min(pos_summary$Quantity),100),RoundTo(max(pos_summary$Quantity),1),500))
plot(bar_chart)
#CLEAN UP
#==========================================================
rm(account,account_balances,account_equity,col_ratio,dai,dai_dollar_balance,dydx,dydx_positions,eth,eth_dollar_balance,leverage,
   my_api.key,my_passphrase,my_secret,names,usdc_oracle_price,x,btc_usd,curr_bal_eth,curr_bal_usd,eth_dai,long_pos,long_pos_summary,neg_balance,
   neg_dai_bal,neg_eth_bal,neg_usdc_bal,owner,pos_balance,pos_dai_bal,pos_eth_bal,pos_summary,pos_usdc_bal,price_change,short_pos,short_pos_summary,
   usdc,usdc_dollar_balance,bar_chart,liq_qty)
