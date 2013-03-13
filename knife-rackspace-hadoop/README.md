How Hadoop Works
================
JobTracker and Namenode service runs on HadoopMaster.

TaskTracker and Datanode service runs on HadoopWorkers.

Client submits jobs to JobTracker.

JobTracker talks to Namenode to determine the location of te data.

JobTracker locates TaskTracker nodes with available slots at or near the data.

JobTracker submits the work to the chosen TaskTracker nodes.

TaskTracker nodes are minotored. If they do not submit heartbeat signals often enough, they are deemed to have failed and work is scheduled on a different TaskTracker.

TaskTracker notifies JobTracker when a job fails. JobTracker decides what to do with the job: resubmit, avoid, blacklist the TaskTracker etc.

Clients can poll the JobTracker for status.

Using Knife from the workstation
================================

	export RACKSPACE_API_USERNAME=username
	export RACKSPACE_API_KEY=api_key
	export RACKSPACE_VERSION=v2
	export RACKSPACE_ENDPOINT=https://dfw.servers.api.rackspacecloud.com/v2

	curl -L "https://raw.github.com/sacharya/random-scripts/master/knife-rackspace-hadoop/chef-knife-install.sh" | bash

	IMAGE_ID=`knife rackspace image list | grep 'CentOS 6.2' | awk '{print $1}'`
	FLAVOR_ID=`knife rackspace flavor list | grep '4096' | awk '{print $1}'`

	knife rackspace server create --server-name hadoopmaster --image $IMAGE_ID --flavor $FLAVOR_ID --environment example --run-list 'role[hadoop-master]' -VV

	knife rackspace server create --server-name hadoopworker1 --image $IMAGE_ID --flavor $FLAVOR_ID --environment example --run-list 'role[hadoop-worker]' -VV


Running Chef-Client on Servers from Workstation
===============================================
	ssh root@server "chef-client"

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

MapReduce Tests
===============
	hadoop jar /usr/lib/hadoop/hadoop-examples-1.0.3.15.jar pi 10 1000000
	
	curl -L "https://raw.github.com/sacharya/random-scripts/master/knife-rackspace-hadoop/wordcount.sh" | bash

What runs where
===============

Web UIs:
	
	http://hadoopmaster:50030 - JobTracker
	
	http://hadoopmaster:50070 - Namenode
 
	http://hadoopworker1:50060 - TaskTrackers
	
	http://hadoopworker1:50075 - Datanodes

Protocols:
	
	http://hadoopmaster:8020 -  Namenode daemon for FileSystem metadata operations 
	
	http://hadoopworker1:50010 - Datanode daemon For DFS Data transfer
