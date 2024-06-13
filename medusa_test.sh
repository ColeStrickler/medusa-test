#!/bin/bash

WSS=2048
apart=part1 # part 1 == bin 0
vpart=part1 # part9 == bins 1-3

killall bandwidth
killall latency
# start co-runners on cores 1,2,3
# with WSS > LLC_SIZE to force requests to go to memory

for i in 1 2 3; do
    ./bandwidth -c $i -m $WSS -t 0 -a write &
    bw_pid=$!
    echo $bw_pid
    echo $bw_pid >> /sys/fs/cgroup/palloc/$apart/tasks
done

echo "WS(KB)    latency(ns)"
./latency -c 0 -m $WSS -i 100 > out.txt 2> /dev/null &
latency_pid=$!
chrt -f -p 99 $latency_pid
echo $latency_pid > /sys/fs/cgroup/palloc/$vpart/tasks
echo $latency_pid
wait $latency_pid

VAL=`grep average out.txt | awk '{ print $2 }'`
echo -e $ws '\t' $VAL
