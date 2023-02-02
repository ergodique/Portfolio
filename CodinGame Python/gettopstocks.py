#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: ergodique
"""



def get_top_stocks(stocks, prices):
    print('Getting Top Stocks:')
    #find average array first
    averages=[]
    topStocks=[]
    sum=0
    for i in range(0,len(stocks)):
        for j in range(0,len(prices)): 
            #print(prices[j][i])
            sum=sum+prices[j][i]
            #print(sum)
        averages.append(sum/len(prices))
        sum=0
        
    print('Averages:')
    print(averages)
    #create a dictionary with key=stock, value=avg price
    stockDict={}
    for i in range(0,len(stocks)):
        stockDict[stocks[i]] = averages[i]
    print('Dictionary:')
    print(stockDict)
    print('Sorted:')
    stockDict=dict(sorted(stockDict.items(), key=lambda item: item[1]))
    print(stockDict)
    keys=list(stockDict.keys())
    #print(keys)
    keys.reverse()
    #print(keys)
    for i in range(0,3):
        topStocks.append(keys[i])
    print(topStocks)
    return topStocks


stocks = ['AMZN','CACC','EQIX','GOOG','ORLY','ULTA']
prices = [[12.81,11.09,12.11,10.93,8.83,8.14],[10.34,10.56,10.14,12.17,13.1,11.22],[11.53,10.98,10.28,12.66,13.25,11.38]]

# print(len(prices))
# print(prices[2][0])
get_top_stocks(stocks, prices)