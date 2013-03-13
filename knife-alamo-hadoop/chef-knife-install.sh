#!/bin/bash

set -x

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Make sure the Openstack Credentials are set.
: ${OPENSTACK_USER:?"Need to set OPENSTACK_USER non-empty"}
: ${OPENSTACK_PASSWORD:?"Need to set OPENSTACK_PASSWORD non-empty"}
: ${OPENSTACK_TENANT:?"Need to set OPENSTACK_TENANT non-empty"}
: ${OPENSTACK_REGION:?"Need to set OPENSTACK_REGION non-empty"}
: ${OPENSTACK_AUTH_URL:?"Need to set OPENSTACK_AUTH_URL non-empty"}

SUDO_USER=root
HOMEDIR=$(getent passwd ${SUDO_USER} | cut -d: -f6)

apt-get update

apt-get install -y --force-yes debconf-utils pwgen

IP=`ifconfig eth0 | grep inet | head -n1 | cut -d":" -f2 | cut -d" " -f1`

#CHEF_URL=${CHEF_URL:-http://$(hostname -f):4000}
CHEF_URL=${CHEF_URL:-http://$IP:4000}
AMQP_PASSWORD=${AMQP_PASSWORD:-$(pwgen -1)}
WEBUI_PASSWORD=${WEBUI_PASSWORD:-$(pwgen -1)}

echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main"| sudo tee /etc/apt/sources.list.d/opscode.list
echo "deb http://apt.opscode.com/ precise-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
sudo mkdir -p /etc/apt/trusted.gpg.d
gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
gpg --export packages@opscode.com|sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg >/dev/null

cat <<EOF | debconf-set-selections
chef chef/chef_server_url string ${CHEF_URL}
chef-solr chef-solr/amqp_password password ${AMQP_PASSWORD}
chef-server-webui chef-server-webui/admin_password password ${WEBUI_PASSWORD}
EOF

apt-get update
apt-get install -y --force-yes opscode-keyring
apt-get upgrade -y --force-yes
apt-get install -y --force-yes chef chef-server

mkdir -p ${HOMEDIR}/.chef
cp /etc/chef/validation.pem /etc/chef/webui.pem ${HOMEDIR}/.chef
chown -R ${SUDO_USER}: ${HOMEDIR}/.chef

cat <<EOF | knife configure -i
${HOMEDIR}/.chef/knife.rb
${CHEF_URL}
chefadmin
chef-webui
${HOMEDIR}/.chef/webui.pem
chef-validator
${HOMEDIR}/.chef/validation.pem

EOF

# Grab the cookbooks and upload them to chef-server
apt-get -y install git-core
git clone https://github.com/sacharya/hdp-cookbooks.git

cat >> /root/.chef/knife.rb <<EOF
cookbook_path ["${HOMEDIR}/hdp-cookbooks/cookbooks"]
EOF

knife cookbook upload -a

# Grab knife-alamo and install it
git clone https://github.com/sacharya/knife-alamo.git
apt-get install -y ruby ruby-dev libopenssl-ruby rdoc ri irb build-essential wget ssl-cert curl
curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
tar zxf rubygems-1.8.10.tgz
cd rubygems-1.8.10 
ruby setup.rb --no-format-executable
gem install chef --no-ri --no-rdoc

cd ..
cd knife-alamo
gem build knife-alamo.gemspec
gem install knife-alamo-*.gem

cat >> /root/.chef/knife.rb <<EOF
knife[:alamo][:openstack_user] = "$OPENSTACK_USER"
knife[:alamo][:openstack_pass] = "$OPENSTACK_PASSWORD"
knife[:alamo][:openstack_tenant] = "$OPENSTACK_TENANT"
knife[:alamo][:openstack_region] = "$OPENSTACK_REGION"
knife[:alamo][:controller_ip] = "$OPENSTACK_AUTH_URL"

knife[:alamo][:instance_login] = "root"
knife[:alamo][:validation_pem]  = "${HOMEDIR}/.chef/validation.pem"
EOF

knife role from file ${HOMEDIR}/hdp-cookbooks/roles/hadoop-datanode.json
knife role from file ${HOMEDIR}/hdp-cookbooks/roles/hadoop-jobtracker.json
knife role from file ${HOMEDIR}/hdp-cookbooks/roles/hadoop-master.json
knife role from file ${HOMEDIR}/hdp-cookbooks/roles/hadoop-namenode.json
knife role from file ${HOMEDIR}/hdp-cookbooks/roles/hadoop-worker.json
knife role from file ${HOMEDIR}/hdp-cookbooks/roles/hadoop-tasktracker.json

knife environment from file ${HOMEDIR}/hdp-cookbooks/environments/example.json

echo "Setup complete!!! You may now proceed..."
