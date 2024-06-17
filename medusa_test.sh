#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <co/no> <WSS(KB)> <corun-type(read/write)>"
    exit 1
fi

corun=$1
WSS=$2
corun_type=$3

type="Solo"

apart=part1 # part 1 == bin 0
vpart=part1 # part9 == bins 1-3

# start co-runners on cores 1,2,3
# with WSS > LLC_SIZE to force requests to go to memory

> /sys/fs/cgroup/palloc/$vpart/cgroup.procs

if [ "$corun" = "co" ]; then
    echo "Beginning corunners...."
    type="Corun"
    for i in 1 2 3; do
        ./bandwidth -c $i -m 2048 -t 0 -a $corun_type > /dev/null 2>&1 &
        bw_pid=$!
        echo $bw_pid
        echo $bw_pid >> /sys/fs/cgroup/palloc/$apart/cgroup.procs
    done
fi

echo -e "\nVictim running...."

chrt -f 99 ./latency -c 0 -m $WSS -i 100 > out.txt 2> /dev/null &
latency_pid=$!
echo $latency_pid >> /sys/fs/cgroup/palloc/$vpart/cgroup.procs
echo $latency_pid
wait $latency_pid

if [ "$corun" = "co" ]; then
    echo "Killing co-runners...."
    killall bandwidth
    wait &> /dev/null
fi

VAL=`grep average out.txt | awk '{ print $2 }'`
echo -e "\nType\tWSS(KB)\tVictim latency(ns)"
echo -e "$type\t$WSS\t$VAL"
