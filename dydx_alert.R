#tracks a specific account for changes in position and alerts you of the position change

rm(list=ls())

library(jsonlite)
library(RPushbullet)

source('_inputs.R')

min_change <- 1 #min amount eth balance has to change by
refresh_rate <- 5 #reresh rate in seconds for pining dydx api
init <- TRUE

account <- '0x4a40e91175fa2f7dd8ae444596c7f5c98c4eac8b'

repeat{
  #============================================================================
  #reset error boolean each time you do an api request
  api_error <- FALSE
  #pull json file from api 
  tryCatch({dydx_account <- fromJSON(paste0('https://api.dydx.exchange/v1/accounts/',account))},
           error = function(e){
             print("DYDX API Connection Error")
             pbPost(type = 'note', title = "DYDX api Error", body = "Check if script is running", email = myEmail, apikey = myAPIkey)
             api_error <<- TRUE
             })
  #if no error pulling data from dydx, run script
  if (!api_error){
    #account balances for ETH, DAI & USDC
    accounts <- as.data.frame(dydx_account$accounts$balances)
    #eth positions
    eth_positions <- accounts[,1]
    #adjust par/wei values to readable notation
    eth_positions$wei <- as.numeric(eth_positions$wei)/10^18
    #sum eth balances
    eth_balance <- round(sum(eth_positions$wei),2)
    #ignore first run through to establish "current_eth_balance"
    if (!init){
      if (eth_balance > current_eth_balance+min_change){
        change <- eth_balance-current_eth_balance
        pbPost(type = 'note', title = "ETH Pos Balance Change", body = paste0("Position increased by: ",change," contracts"), email = myEmail, apikey = myAPIkey)
      }
      
      if(eth_balance < current_eth_balance-min_change){
        change <- eth_balance-current_eth_balance
        pbPost(type = 'note', title = "ETH Neg Balance Change", body = paste0("Position decreased by: ",change," contracts"), email = myEmail, apikey = myAPIkey)
      }
    }
    #Set current value
    current_eth_balance <- eth_balance
  } 
  #============================================================================
  #turn off init-> stays false after first run through
  init <- FALSE
  print(Sys.time())
  Sys.sleep(refresh_rate)
}