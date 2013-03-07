#!/bin/bash

set -x

: ${OPENSTACK_USER:?"Need to set OPENSTACK_USER non-empty"}
: ${OPENSTACK_PASSWORD:?"Need to set OPENSTACK_PASSWORD non-empty"}
: ${OPENSTACK_TENANT:?"Need to set OPENSTACK_TENANT non-empty"}
: ${OPENSTACK_REGION:?"Need to set OPENSTACK_REGION non-empty"}
: ${OPENSTACK_AUTH_URL:?"Need to set OPENSTACK_AUTH_URL non-empty"}

apt-get update

apt-get install -y --force-yes debconf-utils pwgen

CHEF_URL=${CHEF_URL:-http://$(hostname -f):4000}
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

SUDO_USER=root

HOMEDIR=$(getent passwd ${SUDO_USER} | cut -d: -f6)
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


apt-get -y install git-core
git clone https://github.com/rackspace/knife-alamo.git
git clone https://github.com/rackspace/hdp-cookbooks.git

cat >> /root/.chef/knife.rb <<EOF
cookbook_path ["/root/hdp-cookbooks/cookbooks"]
EOF

knife cookbook upload -a

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
knife[:alamo][:openstack_user] = $OPENSTACK_USER
knife[:alamo][:openstack_pass] = $OPENSTACK_PASSWORD
knife[:alamo][:openstack_tenant] = $OPENSTACK_TENANT
knife[:alamo][:openstack_region] = $OPENSTACK_REGION
knife[:alamo][:controller_ip] = $OPENSTACK_AUTH_URL

knife[:alamo][:instance_login] = "root"
knife[:alamo][:validation_pem]  = "/root/.chef/validation.pem"
EOF
