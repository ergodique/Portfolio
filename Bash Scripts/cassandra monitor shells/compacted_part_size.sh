#!/bin/bash

cd /opt/SolarWinds #burayi tmp altinda bir yere alabiliriz...

nodetool tablestats | grep -e "Keyspace" -e "Table: " -e "Compacted partition maximum" > compacted_part.out

while IFS='' read -r line || [[ -n "$line" ]]; do

	if [[ $line == *"Keyspace"* ]]; then
 		in_keyspace=1
 		keyspace="$(echo $line | cut -d " " -f3)"
 		#echo $keyspace
	elif [[ $line == *"Table"* ]]; then
 		in_table=1
 		table="$(echo $line | cut -d " " -f2)"
 		#echo $table
	elif [[ $line == *"Compacted partition maximum bytes"* ]]; then
 		#burada maximum bytes'in boyutunu almak lazim
 		bytes="$(echo $line | cut -d " " -f5)"
 		#echo "MegaBytes: " $(($bytes/1024/1024))
 		megabytes=$(($bytes/1024/1024))
 		if [[ $megabytes -ge 80 ]]; then      #cut bisey
 			echo "Keyspace:" $keyspace
 			echo "Table:" $table
 			echo "Partition_size: " $megabytes
 		fi
 	fi
done < "compacted_part.out"








