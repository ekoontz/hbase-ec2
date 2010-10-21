#!/bin/sh
rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
yum -y install puppet 
echo '10.122.49.123 puppet puppet.ec2.foofers.org' | cat >> /etc/hosts
echo '    runinterval = 10' | cat >> /etc/puppet/puppet.conf
echo "" | cat >> /etc/puppet.conf
/etc/init.d/puppet start

