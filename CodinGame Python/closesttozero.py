#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: ergodique
"""

def closest_to_zero(numbers):
    if(len(numbers)==0):
        return 0
    
    closest = -274
    
    for i in range(0,len(numbers)):
        if (numbers[i] == 0):
            closest = numbers[i]
        elif (numbers[i] > 0 and numbers[i] <= abs(closest)):
            closest = numbers[i]
        elif (numbers[i] < 0 and numbers[i]*-1 < abs(closest)):
            closest = numbers[i]
    
    return closest



numbers=[3,-10, 11.2, 2.8, 4.5, -7.2,-14,-3.71,3.54,-19.6, 3.5,-1.3, -6.2,7.4,1.3]
#numbers=[3,-10, 11.2, 2.8, 4.5, -7.2,-14,-3.71,3.54,-19.6, 3.5,-1.3, -6.2,7.4,0]
#numbers=[]

print(closest_to_zero(numbers))
