#!/bin/sh
#note that this script must run as root (run it with 'sudo sh ./slave.sh').
PUPPET_MASTER_IP=$1
rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
yum -y install puppet 
echo "$PUPPET_MASTER_IP puppet" | cat >> /etc/hosts
echo '    runinterval = 10' | cat >> /etc/puppet/puppet.conf
echo "" | cat >> /etc/puppet.conf
/etc/init.d/puppet start

