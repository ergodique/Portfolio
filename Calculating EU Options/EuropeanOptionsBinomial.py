#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This code is written for European options binomial pricing.
@author: Erdogan Can Unlusoy
"""
import numpy as np

#Question 1(d) the volatility increases with increasing stock price
# Ks=np.arange(100,201,1)
# for i in np.arange(0,101,1):
#     volatility=np.sqrt((0.5*Ks[i+1]**2+0.5*(Ks[i]-1)**2-(0.5*Ks[i+1]+0.5*Ks[i]-1)**2))/100
#     print(volatility)          

        
#Question 2(b) Binomial tree pricing model
opttype = 'C' # Option Type 'C' or 'P'
S0 = 100      # initial stock price
K = 100       # strike price
T = 1         # time to maturity in years
r = 0      # annual risk-free rate
N = 20         # number of time steps
u = 1       # up-factor in binomial models
d = -1*u       # ensure recombining tree
  


def binomial_pricing(K,T,S0,r,N,u,d,opttype):
    #precompute constants
    dt = T/N
    # q = (np.exp(r*dt) - d) / (u-d)
    q=0.5
    #we don't need here discount factor but it is good to show, and write
    # a code that is parameterizable
    disc = np.exp(-r*dt)
    
    # initialise asset prices at maturity for required time steps
    S = S0 + d * (np.arange(N,-1,-1)) + u * (np.arange(0,N+1,1)) 
    # print('Print S')
    # print(S)

    # initialise option values at maturity
    if opttype=='C':
        C = np.maximum( S-K, np.zeros(N+1) )
    else:
        C = np.maximum( K-S, np.zeros(N+1) )
        #Here we need to flip payoff vector because it will be in reverse order for puts
        C = np.flip(C)

    # step backwards through tree
    for i in np.arange(N,0,-1):
        C = disc * ( q * C[1:i+1] + (1-q) * C[0:i] )
    
    return C[0]

# p = binomial_pricing(K,T,S0,r,N,u,d,opttype='C')
# print(p)   

# Final Answer for Question 2(b)
typ=['C','P'] 
Cs=np.arange(80,125,5)
Ps=np.arange(120,75,-5)
print("Pricing Results:")   
for i in typ:
    if i=='C':
        for j in Cs:
            p = binomial_pricing(j,T,S0,r,N,u,d,opttype='C')
            print(f'Call with Strike {j}: {round(p,2)}')
    else:
        for j in Ps:
            p = binomial_pricing(j,T,S0,r,N,u,d,opttype='P')
            print(f'Put with Strike {j}: {round(p,2)}')   
     
        
     