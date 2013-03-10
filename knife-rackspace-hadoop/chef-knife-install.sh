#!/bin/bash

set -x

# Make sure the Rackspace Credentials are set.
: ${RACKSPACE_API_USERNAME:?"Need to set RACKSPACE_API_USERNAME non-empty"}
: ${RACKSPACE_API_KEY:?"Need to set RACKSPACE_API_KEY non-empty"}
: ${RACKSPACE_VERSION:?"Need to set RACKSPACE_VERSION non-empty"}
: ${RACKSPACE_ENDPOINT:?"Need to set RACKSPACE_ENDPOINT non-empty"}


apt-get update

apt-get install -y --force-yes debconf-utils pwgen

IP=`ifconfig eth0 | grep 'inet addr:' | awk '{ print $2 }' | awk -F: '{print $2}'`

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

# Grab the cookbooks and upload them to chef-server
apt-get -y install git-core
git clone https://github.com/rackspace/hdp-cookbooks.git

cat >> /root/.chef/knife.rb <<EOF
cookbook_path ["/root/hdp-cookbooks/cookbooks"]
EOF

knife cookbook upload -a

# Grab knife-alamo and install it
git clone https://github.com/opscode/knife-rackspace.git
apt-get install -y ruby ruby-dev libopenssl-ruby rdoc ri irb build-essential wget ssl-cert curl
curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
tar zxf rubygems-1.8.10.tgz
cd rubygems-1.8.10 
ruby setup.rb --no-format-executable
gem install chef --no-ri --no-rdoc

cd ..
cd knife-rackspace
apt-get install -y libxslt-dev libxml2-dev
gem install nokogiri

gem build knife-rackspace.gemspec
gem install knife-rackspace-*.gem

cat >> /root/.chef/knife.rb <<EOF
knife[:rackspace_api_username] = "$RACKSPACE_API_USERNAME"
knife[:rackspace_api_key] = "$RACKSPACE_API_KEY"
knife[:rackspace_version] = "$RACKSPACE_VERSION"
knife[:rackspace_endpoint] = "$RACKSPACE_ENDPOINT"
EOF

knife role from file /root/hdp-cookbooks/roles/hadoop-datanode.json
knife role from file /root/hdp-cookbooks/roles/hadoop-jobtracker.json
knife role from file /root/hdp-cookbooks/roles/hadoop-master.json
knife role from file /root/hdp-cookbooks/roles/hadoop-namenode.json
knife role from file /root/hdp-cookbooks/roles/hadoop-worker.json
knife role from file /root/hdp-cookbooks/roles/hadoop-tasktracker.json

echo "Setup complete!!! You may now proceed..."
