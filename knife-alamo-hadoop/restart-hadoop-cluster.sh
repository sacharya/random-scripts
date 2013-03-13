#!/bin/bash

set -x

SSH_USERNAME="root"

function execute() {
    local IP="$1"
    local CMD="$2"
    ssh -i mykey.pem -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no $SSH_USERNAME@$IP $CMD &
}

masters=`knife status 'chef_environment:openstack AND role:hadoop-master' | awk '{print $6}' | cut -d"," -f1`
for master in $masters; do
    echo "Restarting master $master"
    execute $master "chef-client && /etc/init.d/hadoop-namenode restart && /etc/init.d/hadoop-jobtracker restart"
done

workers=`knife status 'chef_environment:openstack AND role:hadoop-worker' | awk '{print $6}' | cut -d"," -f1`
for worker in $workers; do
    echo "Restarting worker $worker"
    execute $worker "chef-client && /etc/init.d/hadoop-datanode restart && /etc/init.d/hadoop-tasktracker restart"
    NPROC=$(($NPROC+1))
    if [ "$NPROC" -ge 6 ]; then
        wait
        NPROC=0
    fi
done
echo "Complete!"
