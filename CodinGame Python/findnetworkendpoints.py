#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: ergodique
"""

def find_network_endpoint(start_node_id,from_ids,to_ids):
    
    
    print(start_node_id)
    from_index=from_ids.index(start_node_id)
    
    if from_index == len(from_ids)-1:
        return to_ids[len(to_ids)-1]
    else:
        return find_network_endpoint(to_ids[from_index], from_ids, to_ids) 
    




from_ids=[1,7,3,4,2,6,9,5]
to_ids=[3,3,4,6,6,9,5,7]
start_node_id=1
print(find_network_endpoint(start_node_id, from_ids, to_ids))