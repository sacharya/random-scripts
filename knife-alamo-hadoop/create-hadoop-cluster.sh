#!/bin/bash

set -x

read -p "Enter the Image id: " IMAGE_ID
echo $IMAGE_ID

read -p "Enter the Flavor Id: " FLAVOR_ID
echo $FLAVOR_ID

read -p "Enter the Chef Environment name: " ENV_NAME
echo $ENV_NAME

cp /root/hdp-cookbooks/environments/example.json /root/hdp-cookbooks/environments/$ENV_NAME.json
sed -i "s/example/$ENV_NAME/g" /root/hdp-cookbooks/environments/$ENV_NAME.json
knife environment from file /root/hdp-cookbooks/environments/$ENV_NAME.json

read -p "Enter the number of worker nodes: " NUMBER

knife alamo server create --name $ENV_NAME-hadoopmaster --image $IMAGE_ID --flavor $FLAVOR_ID --chefenv $ENV_NAME --privkey mykey.pem --runlist 'role[hadoop-master]' -VV

for i in $(eval echo "{1..$NUMBER}")
  do
    echo "Creating Worker $i"
    knife alamo server create --name $ENV_NAME-hadoopworker$i --image $IMAGE_ID --flavor $FLAVOR_ID --chefenv $ENV_NAME --privkey mykey.pem --runlist 'role[hadoop-worker]' &
    NPROC=$(($NPROC+1))
    if [ "$NPROC" -ge 6 ]; then
        wait
        NPROC=0
    fi
done

