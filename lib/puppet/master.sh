#!/bin/sh
set -x
cd ~

wget http://ekoontz-tarballs.s3.amazonaws.com/jdk1.6.0_22.tar.gz
tar xfz jdk1.6.0_22.tar.gz

wget http://ekoontz-tarballs.s3.amazonaws.com/apache-ant-1.8.1-bin.tar.bz2
tar xfj apache-ant-1.8.1-bin.tar.bz2

export JAVA_HOME=`pwd`/jdk1.6.0_22
export PATH=$JAVA_HOME/bin:`pwd`/apache-ant-1.8.1/bin:$PATH
export PATH=`pwd`/apache-maven-3.0/bin:$JAVA_HOME:$PATH

sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
sudo yum -y install puppet-server git emacs

wget http://ekoontz-tarballs.s3.amazonaws.com/apache-maven-3.0-bin.tar.gz
tar xfz apache-maven-3.0-bin.tar.gz
export PATH=`pwd`/apache-maven-3.0/bin:$JAVA_HOME:$PATH

wget http://ekoontz-tarballs.s3.amazonaws.com/m2.tar.gz
tar xfz m2.tar.gz

git clone git://github.com/ekoontz/hbase-ec2.git
cd hbase-ec2
git checkout origin/puppet

cd ~
git clone git://github.com/trendmicro/hadoop-common.git
cd hadoop-common
git checkout yahoo-hadoop-0.20.104-append
ant clean compile
cp ~/hbase-ec2/lib/puppet/hdfs-site.xml conf
cp ~/hbase-ec2/lib/puppet/mapred-site.xml conf

cd ~
git clone git://github.com/apache/zookeeper.git
cd zookeeper
ant clean compile
cp ~/hbase-ec2/lib/puppet/zoo.cfg conf

cd ~
git clone git://github.com/trendmicro/hbase.git 
cd hbase
git checkout security
mvn clean compile dependency:build-classpath -Dmdep.outputFile=target/cached_classpath.txt
cp ~/hbase-ec2/lib/puppet/hbase-site.xml conf

cd ~
wget -O jre.bin "http://ekoontz-tarballs.s3.amazonaws.com/jre-6u22-linux-x64.bin"
sh ./jre.bin

# done compiling stuff: now copy it all to where puppetmaster can find it.
cd ~
mkdir -p /tmp/puppetfiles

tar  --exclude=".git*" -czf /tmp/puppetfiles/hadoop-common.tar.gz hadoop-common
tar  --exclude=".git*" -czf /tmp/puppetfiles/hbase.tar.gz hbase
tar -czf /tmp/puppetfiles/jre.tar.gz jre1.6.0_22
tar -czf /tmp/puppetfiles/m2.tar.gz .m2
tar -czf /tmp/puppetfiles/zookeeper.tar.gz zookeeper
cp ~/hbase-ec2/lib/initscripts/* /tmp/puppetfiles
export PUPPET_MASTER_IP=`/sbin/ifconfig eth0 | grep "inet addr" | cut -d: -f2-2 | cut -d' ' -f1`
cp /etc/hosts /tmp/puppetfiles/hosts
echo "$PUPPET_MASTER_IP    puppet namenode zookeeper jobtracker master" >> /tmp/puppetfiles/hosts

sudo cp /tmp/puppetfiles/hosts /etc

#start up puppet server
sudo cp hbase-ec2/lib/puppet/puppet.conf /etc/puppet/
sudo cp hbase-ec2/lib/puppet/manifests/site.pp /etc/puppet/manifests/
sudo cp hbase-ec2/lib/puppet/fileserver.conf /etc/puppet

sudo /etc/init.d/puppetmaster start

#turn off (comment out) requiretty so that sudo-using services can start from puppet.
sudo cat /etc/sudoers | perl -pe 's/^(Defaults\s+requiretty)/#\1/' > /tmp/sudoers 
chmod 400 /tmp/sudoers 
sudo cp /tmp/sudoers /etc

#start puppet slave on this host.
sudo sh hbase-ec2/lib/puppet/slave.sh $PUPPET_MASTER_IP

