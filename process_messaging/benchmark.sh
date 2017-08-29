#!/bin/bash

arr=( $(pwgen 1 1) $(pwgen 100 1) $(pwgen 1000 1) $(pwgen 8000 1) )
n=(1 1000 2000 10000)
echo "Starting Benchmarks"
for str in "${arr[@]}"
do
  echo "For message sizes of ${#str}"
  echo "For message sizes of ${#str}" >> benchmarks.txt
  for i in "${n[@]}"
  do
    echo "$i : $(mix run -e SB.runner\($i,\"$str\"\))" >>benchmarks.txt
  done
done
