Using Knife from the workstation
================================

export RACKSPACE_API_USERNAME=username
export RACKSPACE_API_KEY=api_key
export RACKSPACE_VERSION=v2
export RACKSPACE_ENDPOINT=https://dfw.servers.api.rackspacecloud.com/v2

curl -L "https://raw.github.com/sacharya/random-scripts/master/knife-rackspace-hadoop/chef-knife-install.sh" | bash

IMAGE_ID=`knife rackspace image list | grep 'CentOS 6.2' | awk '{print $1}'`
FLAVOR_ID=`knife rackspace flavor list | grep '4096' | awk '{print $1}'`

knife environment from file /root/hdp-cookbooks/environments/example.json

knife rackspace server create --server-name hadoopmaster --image $IMAGE_ID --flavor $FLAVOR_ID --environment example --run-list 'role[hadoop-master]' -VV

knife rackspace server create --server-name hadoopworker1 --image $IMAGE_ID --flavor $FLAVOR_ID --environment example --run-list 'role[hadoop-worker]' -VV

What servives are running
=========================
jps

How to restart services
=======================
/etc/init.d/hadoop-tasktracker restart
/etc/init.d/hadoop-datanode restart

/etc/init.d/hadoop-namenode restart
/etc/init.d/hadoop-jobtracker restart

Logs
====
/var/log/hadoop

Config files
===========
/etc/hadoop/conf

Mapreduce Tests
===============
hadoop jar /usr/lib/hadoop/hadoop-examples-1.0.3.15.jar pi 10 1000000
curl -L "https://raw.github.com/sacharya/random-scripts/master/knife-rackspace-hadoop/wordcount.sh" | bash


