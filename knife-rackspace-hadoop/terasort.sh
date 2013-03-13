#!/bin/bash

set -x

now=`date +"%y%m%d-%H%M"`
hadoop jar /usr/lib/hadoop/hadoop-examples-1.0.3.15.jar teragen -D dfs.block.size=536870912 500000000 /terasort/$now/input
hadoop jar /usr/lib/hadoop/hadoop-examples-1.0.3.15.jar terasort /terasort/$now/input /terasort/$now/output
