sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
sudo yum -y install puppet-server puppet git
mkdir /tmp/puppetfiles
git clone git://github.com/ekoontz/hbase-ec2.git
cd hbase-ec2
git checkout puppet
sudo cp lib/puppet/puppet.conf /etc/puppet
sudo cp lib/puppet/manifests/site.pp /etc/puppet/manifests/
sudo cp lib/puppet/fileserver.conf /etc/puppet

export PUPPET_MASTER_IP=`/sbin/ifconfig eth0 | grep "inet addr" | cut -d: -f2-2 | cut -d' ' -f1`
echo "$PUPPET_MASTER_IP    puppet" >> /tmp/hosts
echo "$PUPPET_MASTER_IP    puppet namenode zookeeper jobtracker master" >> /tmp/puppetfiles/hosts
sudo cp /tmp/hosts /etc

sudo /etc/init.d/puppetmaster start
sudo /etc/init.d/puppet start


