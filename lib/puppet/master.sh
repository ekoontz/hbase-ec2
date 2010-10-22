#!/bin/sh

sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
sudo yum -y install puppet-server screen git ant

cd ~
wget -O jdk.bin "http://ekoontz-tarballs.s3.amazonaws.com/jdk-6u22-linux-x64.bin"
sh ./jdk.bin
export JAVA_HOME=`pwd`/jdk1.6.0_22
export PATH=$JAVA_HOME:$PATH

wget http://ekoontz-tarballs.s3.amazonaws.com/apache-maven-3.0-bin.tar.gz
tar xfz apache-maven-3.0-bin.tar.gz
export PATH=`pwd`/apache-maven-3.0/bin:$JAVA_HOME:$PATH

git clone git://github.com/ekoontz/hbase-ec2.git
cd hbase-ec2
git checkout puppet
cd ~

git clone git://github.com/trendmicro/hadoop-common.git
cd hadoop-common
git checkout yahoo-hadoop-0.20.104-append
ant clean compile
cat ~/hbase-ec2/lib/puppet/hdfs-site.xml | perl -pe "s/HOSTNAMEF/`hostname -f`/" > /tmp/hdfs-site.xml
mv /tmp/hdfs-site.xml conf
cd hadoop-common
bin/hadoop namenode -format
screen -S namenode bin/hadoop namenode
cd ~

git clone git://github.com/apache/zookeeper.git
cd zookeeper
ant clean compile
cat ~/hbase-ec2/lib/puppet/zoo.cfg | perl -pe "s/HOSTNAMEF/`hostname -f`/" > /tmp/zoo.cfg
cp /tmp/zoo.cfg conf
bin/zkServer start
cd ~

git clone git://github.com/trendmicro/hbase.git 
cd hbase
git checkout security
mvn clean compile
cat ~/hbase-ec2/lib/puppet/hbase-site.xml | perl -pe "s/HOSTNAMEF/`hostname -f`/" > /tmp/hbase-site.xml
cp /tmp/hbase-site.xml conf
#edit with perl and hostname -f..
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
set +x


cp ~/hbase-ec2/lib/puppet/hadoop.sh /tmp/puppetfiles

#start up puppet server
sudo cp hbase-ec2/lib/puppet/puppet.conf /etc/puppet/
sudo cp hbase-ec2/lib/puppet/manifests/site.pp /etc/puppet/manifests/
sudo cp hbase-ec2/lib/puppet/fileserver.conf /etc/puppet

sudo /etc/init.d/puppetmaster start
export PUPPET_MASTER_IP=`/sbin/ifconfig eth0 | grep "inet addr" | cut -d: -f2-2 | cut -d' ' -f1`

#start puppet slave on this host.
sudo sh hbase-ec2/lib/puppet/slave.sh $PUPPET_MASTER_IP

