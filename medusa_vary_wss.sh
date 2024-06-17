#!/bin/bash

wss=(2048 4096 8192 16384)

OUT=outputs/medusa_vary.txt

echo -e "Type\tWSS(KB)\tVictim Latency(ns)\tVictim Slowdown" > $OUT
cat $OUT

for i in ${wss[@]}; do
    solo=$(./medusa_test.sh no $i write | tail -1 | grep $i)
    solo_lat=$(echo $solo | awk '{ print $3 }')
    echo -e "$solo\t\t\t1.00" >> $OUT
    
    sleep 1
    
    corun=$(./medusa_test.sh co $i write | tail -1 | grep $i)
    corun_lat=$(echo $corun | awk '{ print $3 }')
    slowdown=$(bc <<< "scale=2; $corun_lat/$solo_lat")
    
    out="$corun\t\t\t$slowdown"
    echo -e "$out"
    echo -e "$out" >> $OUT
done
