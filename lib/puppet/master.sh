#!/bin/sh

sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
sudo yum -y install puppet-server puppet screen git emacs ant

cd ~
wget -O jdk.bin "http://ekoontz-tarballs.s3.amazonaws.com/jdk-6u22-linux-x64.bin"
sh ./jdk.bin
export JAVA_HOME=`pwd`/jdk1.6.0_22
export PATH=$JAVA_HOME:$PATH

wget http://ekoontz-tarballs.s3.amazonaws.com/apache-maven-3.0-bin.tar.gz
tar xfz apache-maven-3.0-bin.tar.gz
export PATH=`pwd`/apache-maven-3.0/bin:$JAVA_HOME:$PATH

git clone git://github.com/trendmicro/hadoop-common.git
cd hadoop-common
git checkout yahoo-hadoop-0.20.104-append
ant clean compile
# edit hdfs-site.xml
cd hadoop-common
bin/hadoop namenode -format
screen -S namenode bin/hadoop namenode
cd ~

git clone git://github.com/apache/zookeeper.git
cd zookeeper
ant clean compile
# edit conf/zoo.cfg
bin/zkServer start
cd ~

git clone git://github.com/trendmicro/hbase.git 
cd hbase
git checkout security
mvn clean compile
# edit hbase-site.xml
# start master
screen -S master bin/hbase master start
cd ~

wget -O jre.bin "http://ekoontz-tarballs.s3.amazonaws.com/jre-6u22-linux-x64.bin"
sh ./jre.bin

mkdir -p /tmp/puppetfiles
set -x
tar  --exclude=".git*" -czf /tmp/puppetfiles/hadoop-common.tar.gz hadoop-common
tar  --exclude=".git*" -czf /tmp/puppetfiles/hbase.tar.gz hbase
tar -czf /tmp/puppetfiles/jre.tar.gz jre1.6.0_22
tar -czf /tmp/puppetfiles/m2.tar.gz .m2

cp ~/puppet/hadoop.sh /tmp/puppetfiles

#start up puppet server and client.
#cp files to /etc/puppet/puppetmaster.conf, /etc/puppet/fileserver.conf and /etc/puppet/manifests/site.pp.

sudo /etc/init.d/puppetmaster start
sudo /etc/init.d/puppet start
PUPPET_MASTER_IP=`hostname -f`
sudo "echo \"$PUPPET_MASTER_IP puppet puppet.ec2.foofers.org\" | cat >> /etc/hosts"

