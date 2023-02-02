
def solution(markets,trades):
    trades_list=trades.split('|')
    markets_list=markets.split('|')
    pnl_list=[]
    total_pnl=0
    #assuming invalid data is empty string or a string that doesn't have | delimeter
    if (len(trades_list)==1 and not trades_list[0]) or (len(markets_list)==1 and not markets_list[0]):
        return -1
    
    for trade in trades_list:
        market=trade.split(',',2)[0]
        trade_price=float(trade.split(',',2)[1])
        size=float(trade.split(',',2)[2])
        # print(market)
        # print(trade_price)
        # print(size)
        market_index=[markets_list.index(i) for i in markets_list if market in i]
        #print(market_index)
        #check if market variable is empty. In this case the pnl should be zero.
        if len(market_index)==0:
            pnl=0
            continue
        bid=float(markets_list[market_index[0]].split(',',2)[2])
        ask=float(markets_list[market_index[0]].split(',',2)[1])
        # print(bid)
        # print(ask)
        if size > 0:
            pnl=(bid-trade_price)*size
        else:
            pnl=(ask-trade_price)*size
        #print(pnl)

        pnl_list.append(pnl)
    #print(pnl_list)    
    total_pnl=sum(pnl_list)
    return total_pnl   
    
# try with empty strings to see if it returns -1    
# markets=""    
# markets="|FTSE100,6920,6910|"
# trades=""
markets="FTSE100,6920,6910|DAX,9620,9610|GBPUSD,0.0006,0.0004"
#try trades with an unlisted market like AAA to check if that trade's pnl is read correctly
#trades="FTSE100,6900.4,5.1|FTSE100,6910.1,-6.2|DAX,9620,2.5|AAA,10000,10001"
trades="FTSE100,6900.4,5.1|FTSE100,6910.1,-6.2|DAX,9620,2.5"
trades_list=trades.split('|')
markets_list=markets.split('|')

print(solution(markets,trades))
