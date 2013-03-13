#!/bin/bash

set -x

IMAGE_ID=`knife rackspace image list | grep 'CentOS 6.2' | awk '{print $1}'`
echo $IMAGE_ID

FLAVOR_ID=`knife rackspace flavor list | grep '4096' | awk '{print $1}'`
echo $FLAVOR_ID

read -p "Enter the Chef Environment name: " ENV_NAME

cp /root/hdp-cookbooks/environments/example.json /root/hdp-cookbooks/environments/$ENV_NAME.json
sed -i "s/example/$ENV_NAME/g" /root/hdp-cookbooks/environments/$ENV_NAME.json
knife environment from file /root/hdp-cookbooks/environments/$ENV_NAME.json

read -p "Enter the number of worker nodes: " NUMBER

knife rackspace server create --server-name $ENV_NAME-hadoopmaster --image $IMAGE_ID --flavor $FLAVOR_ID --environment $ENV_NAME --run-list 'role[hadoop-master]'

for i in $(eval echo "{1..$NUMBER}")
  do
    echo "Creating Worker $i"
    knife rackspace server create --server-name $ENV_NAME-hadoopworker$i --image $IMAGE_ID --flavor $FLAVOR_ID --environment $ENV_NAME --run-list 'role[hadoop-worker]' &
    NPROC=$(($NPROC+1))
    if [ "$NPROC" -ge 6 ]; then
        wait
        NPROC=0
    fi
done
