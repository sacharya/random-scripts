#!/bin/bash

set -x

hadoop fs -rmr /shakespeare
cd /tmp
wget http://homepages.ihug.co.nz/~leonov/shakespeare.tar.bz2
tar xjvf shakespeare.tar.bz2
now=`date +"%y%m%d-%H%M"`
hadoop fs -put /tmp/Shakespeare /shakespeare/$now/input
hadoop jar /usr/lib/hadoop/hadoop-examples-1.0.3.15.jar wordcount /shakespeare/$now/input /shakespeare/$now/output
hadoop fs -cat /shakespeare/$now/output/part-r-* | sort -nk2
