# DYDX Exchange Analysis
  One the the best advantages of decentralized exchanges is that positions are embedded into smart contracts and are essentially public domain.  This means that as a trader, it can be beneficial to see what positions people have and the overall leverage on a particular exchange.  
  This project will attempt to create a dashboard inwhich various tools and metrics can be looked at to aid in decision making and risk management of positions.  

## Getting Started

Programs to download:
- You can download the latest R [here](https://cran.r-project.org/bin/windows/base/)
- You can download RStudio [here](https://rstudio.com/products/rstudio/download/)
- Signup for Pusbullet [here](https://www.pushbullet.com/) and get the phone app and/or browser extension to be notified of trades
- dydx api link is [here] (https://docs.dydx.exchange/#/)
- dydx liquidator for ETH is [here](https://github.com/dydxprotocol/liquidator)
- It is advisable to set up your own node for your liquidator. This is a reliable one [here](https://www.quiknode.io/)

Installation instructions:
1. Clone repository and install unzipped folder within Documents (or where you like)
2. Open the _input.R file and update the API keys for Coinbase Pro and also PushBullet
3. Install rgdax package using the following code in R console of Rstudio 
```
install.packages('devtools')
library(devtools)
install_github("Guceri/rgdax", ref = "dev")
```
4. Launch Rstudio and set working directory to the folder (the various files are interlinked with each other)

If there are any issues, please let me know.  The instructions are not exhaustive and not meant for complete beginners. 

## TODO List
- [ ] create similar tools for new perpetual BTC contract
- [ ] create a dashboard where all information can be viewed on one page (shiny app)
- [ ] quality control check on liquidator values and expirations

## [Account Liquidation Levels](dydx_liq.R)

  The idea here is to look at all the margin positions on ETH and to identify at what price each account would be liquidated at.  This is useful in assessing risk, opportunistically pricing liquidation events, and to potential use as an aid for running the liquidation bot that dydx provides for people. The larger the potential liquidation, the larger you want to set your fee amount to beat out other liquidators on trades.  

## [dydx Network Details](dydx_network.R)
  This is information that is readily available on the dydx website.  The reason for creating this was to have an "in house" value that can be used for research.  There are now endpoints that can give these high level values without all the necessary computation. 

## [Coinbase vs. dydx Price Edge](dydx_vs_coinbase.R)
  This was a simple tool/widget idea that could be used to incorporate in stragety development.  It basically will calculate how much edge there in when the ETH/DAI markets are out of line between coinbase and dydx.  This is likely to be embedded into strategy development later.

## [dydx Position Expiration Dates](dydx_exp.R)
  Positions are dydx are/were subject to a 28 day max holding period (please verify this yourself as things are constantly changing).  Because of the expiration, positions will be automatically closed by the liquidator if they are not closed and reopened.  This usually happens when someone overlooks this detail and has a low leverage position.  This is likely to be shelved in the near future.

## [Single Account Details](dydx_accounts.R)
  Looking at individual accounts can be useful especially when looking at large position holders and seeing what their leverage is currently at.  The second part to this analysis is below.

## [Single Account Position Change Alert](dydx_alert.R)
  If there is an account you would like to watch (including your own) you can do so with this constantly updating script that tracks specific accounts for position movement. This can be useful when you want to know if a large account is trading or if you order was filled at some point while you were away from the computer. 
