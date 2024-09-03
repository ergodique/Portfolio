
# Placing Orders
After making a client object i.e. `client = schwabdev.Client(...)` we can place orders using the `client.order_place(...)` method.
> Syntax: `client.order_place(account_hash, order)`  
> * Param account_hash(str): account hash to get place order on.  
> * Param order(dict): Order dict to place, there are examples below and in the Schwab documentation. 
> 
> Returns(request.Response):  Response object.  
>> Get the order id by checking the headers.  
>> `order_id = resp.headers.get('location', '/').split('/')[-1]`  
>> *If order is immediately filled then the id might not be returned*

## Order Examples
*Please adjust for your usage.*

### Buy 10 shares of AMD at Market price.

```py
order = {"orderType": "MARKET",
         "session": "NORMAL",
         "duration": "DAY",
         "orderStrategyType": "SINGLE",
         "orderLegCollection": [
             {
                 "instruction": "BUY",
                 "quantity": 10,
                 "instrument": {
                     "symbol": "AMD",
                     "assetType": "EQUITY"
                 }
             }
            ]
         }
```

### Buy 4 shares of INTC at limit price $10.00 

```py
order = {"orderType": "LIMIT", 
         "session": "NORMAL", 
         "duration": "DAY", 
         "orderStrategyType": "SINGLE", 
         "price": '10.00',
         "orderLegCollection": [
             {"instruction": "BUY", 
              "quantity": 4, 
              "instrument": {
                  "symbol": "INTC", 
                  "assetType": "EQUITY"
              }
              }
         ]
         }
```

### Sell 3 options example
*Symbol format:* Underlying Symbol (6 chars including spaces) + Expiration (YYMMDD, 6 chars) + Call/Put (1 char) + Strike Price (5+3=8 chars)
```py
order = {'orderType': 'LIMIT',
         'session': 'NORMAL',
         'price': 1.0,
         'duration': 'GOOD_TILL_CANCEL',
         'orderStrategyType': 'SINGLE',
         'complexOrderStrategyType': 'NONE',
         'orderLegCollection': [
             {'instruction': 'SELL_TO_OPEN',
              'quantity': 3,
              'instrument': {'symbol': 'AAPL  240517P00190000',
                             'assetType': 'OPTION'
                             }
              }
         ]
         }
```

### Buy 3 options example
*Symbol format:* Underlying Symbol (6 chars including spaces) + Expiration (YYMMDD, 6 chars) + Call/Put (1 char) + Strike Price (5+3=8 chars)
```py
order = {'orderType': 'LIMIT',
         'session': 'NORMAL',
         'price': 0.1,
         'duration': 'GOOD_TILL_CANCEL',
         'orderStrategyType': 'SINGLE',
         'complexOrderStrategyType': 'NONE',
         'orderLegCollection': [
             {'instruction': 'BUY_TO_OPEN',
              'quantity': 3,
              'instrument': {'symbol': 'AAPL  240517P00190000',
                             'assetType': 'OPTION'
                             }
              }
         ]
         }
```

### Buy Limited Vertical Call Spread
```py
order = {
    "orderType": "NET_DEBIT",
    "session": "NORMAL",
    "price": "0.10",
    "duration": "DAY",
    "orderStrategyType": "SINGLE",
    "orderLegCollection": [
        {
            "instruction": "BUY_TO_OPEN",
            "quantity": 2,
            "instrument": {
                "symbol": "XYZ   240315P00045000",
                "assetType": "OPTION"
            }
        },
        {
            "instruction": "SELL_TO_OPEN",
            "quantity": 2,
            "instrument": {
                "symbol": "XYZ   240315P00043000",
                "assetType": "OPTION"
            }
        }
    ]
}
```

### Conditional Order: If 10 shares XYZ filled then sell 10 shares ABC.
```py
order = {"orderType": "LIMIT",
         "session": "NORMAL",
         "price": "34.97",
         "duration": "DAY",
         "orderStrategyType": "TRIGGER",
         "orderLegCollection": [
             {
                 "instruction": "BUY",
                 "quantity": 10,
                 "instrument": {
                     "symbol": "XYZ",
                     "assetType": "EQUITY"
                 }
             }
         ],
         "childOrderStrategies": [
             {
                 "orderType": "LIMIT",
                 "session": "NORMAL",
                 "price": "42.03",
                 "duration": "DAY",
                 "orderStrategyType": "SINGLE",
                 "orderLegCollection": [
                     {
                         "instruction": "SELL",
                         "quantity": 10,
                         "instrument": {
                             "symbol": "ABC",
                             "assetType": "EQUITY"
                         }
                     }
                 ]
             }
         ]
         }
```

### Conditional Order: If 2 shares XYZ filled then cancel sell 2 shares ABC.

```py
order = {"orderStrategyType": "OCO",
         "childOrderStrategies": [
             {
                 "orderType": "LIMIT",
                 "session": "NORMAL",
                 "price": "45.97",
                 "duration": "DAY",
                 "orderStrategyType": "SINGLE",
                 "orderLegCollection": [
                     {
                         "instruction": "SELL",
                         "quantity": 2,
                         "instrument": {
                             "symbol": "XYZ",
                             "assetType": "EQUITY"
                         }
                     }
                 ]
             },
             {
                 "orderType": "STOP_LIMIT",
                 "session": "NORMAL",
                 "price": "37.00",
                 "stopPrice": "37.03",
                 "duration": "DAY",
                 "orderStrategyType": "SINGLE",
                 "orderLegCollection": [
                     {
                         "instruction": "SELL",
                         "quantity": 2,
                         "instrument": {
                             "symbol": "ABC",
                             "assetType": "EQUITY"
                         }
                     }
                 ]
             }
         ]
         }
```

### Conditional Order: If 5 shares XYZ filled then sell 5 shares ABC and 5 shares IJK.
```py
order = {"orderStrategyType": "TRIGGER",
         "session": "NORMAL",
         "duration": "DAY",
         "orderType": "LIMIT",
         "price": 14.97,
         "orderLegCollection": [
             {
                 "instruction": "BUY",
                 "quantity": 5,
                 "instrument": {
                     "assetType": "EQUITY",
                     "symbol": "XYZ"
                 }
             }
         ],
         "childOrderStrategies": [
             {
                 "orderStrategyType": "OCO",
                 "childOrderStrategies": [
                     {
                         "orderStrategyType": "SINGLE",
                         "session": "NORMAL",
                         "duration": "GOOD_TILL_CANCEL",
                         "orderType": "LIMIT",
                         "price": 15.27,
                         "orderLegCollection": [
                             {
                                 "instruction": "SELL",
                                 "quantity": 5,
                                 "instrument": {
                                     "assetType": "EQUITY",
                                     "symbol": "ABC"
                                 }
                             }
                         ]
                     },
                     {
                         "orderStrategyType": "SINGLE",
                         "session": "NORMAL",
                         "duration": "GOOD_TILL_CANCEL",
                         "orderType": "STOP",
                         "stopPrice": 11.27,
                         "orderLegCollection": [
                             {
                                 "instruction": "SELL",
                                 "quantity": 5,
                                 "instrument": {
                                     "assetType": "EQUITY",
                                     "symbol": "IJK"
                                 }
                             }
                         ]
                     }
                 ]
             }
         ]
         }
```

### Sell Trailing Stop: 10 shares XYZ with a trailing stop price of 10 (offset).
```py
order = {"complexOrderStrategyType": "NONE",
         "orderType": "TRAILING_STOP",
         "session": "NORMAL",
         "stopPriceLinkBasis": "BID",
         "stopPriceLinkType": "VALUE",
         "stopPriceOffset": 10,
         "duration": "DAY",
         "orderStrategyType": "SINGLE",
         "orderLegCollection": [
             {
                 "instruction": "SELL",
                 "quantity": 10,
                 "instrument": {
                     "symbol": "XYZ",
                     "assetType": "EQUITY"
                 }
             }
         ]
         }
```