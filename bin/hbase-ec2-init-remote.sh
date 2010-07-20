#!/usr/bin/env bash

set -x
export JAVA_HOME=/usr/local/jdk1.6.0_20

ln -s $JAVA_HOME /usr/local/jdk

# Script that is run on each EC2 instance on boot. It is passed in the EC2 user
# data, so should not exceed 16K in size.

MASTER_HOST=$1
ZOOKEEPER_QUORUM=$2
NUM_SLAVES=$3
EXTRA_PACKAGES=$4
SECURITY_GROUPS=`wget -q -O - http://169.254.169.254/latest/meta-data/security-groups`
IS_MASTER=`echo $SECURITY_GROUPS | awk '{ a = match ($0, "-master$"); if (a) print "true"; else print "false"; }'`
IS_AUX=`echo $SECURITY_GROUPS | awk '{ a = match ($0, "-aux$"); if (a) print "true"; else print "false"; }'`
if [ "$IS_MASTER" = "true" ]; then
 MASTER_HOST=`wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname`
fi
MASTER_HOST=$(echo "$MASTER_HOST" | tr '[:upper:]' '[:lower:]')

HADOOP_HOME=`ls -d /usr/local/hadoop-* | grep -v tar.gz | head -n1`
HADOOP_VERSION=`echo $HADOOP_HOME | cut -d '-' -f 2`
HBASE_HOME=`ls -d /usr/local/hbase-* | grep -v tar.gz | head -n1`
HBASE_VERSION=`echo $HBASE_HOME | cut -d '-' -f 2`

HADOOP_SECURE_DN_USER=hadoop

HOSTNAME=`hostname --fqdn | awk '{print tolower($1)}'`
HOST_IP=$(host $HOSTNAME | awk '{print $4}')

echo "HADOOP HOME: ${HADOOP_HOME}; HADOOP_VERSION: ${HADOOP_VERSION}"
echo "HBASE HOME: ${HBASE_HOME}; HBASE_VERSION: ${HBASE_VERSION}"

export USER="root"


############
# Common functions
#

add_client() {
  user=$1
  pass=$2
  kt=$3
  host=$4
  /usr/kerberos/sbin/kadmin -p $user -w $pass <<EOF 
add_principal -randkey host/$host
add_principal -randkey hadoop/$host
add_principal -randkey hbase/$host
ktadd -k $kt host/$host
ktadd -k $kt hadoop/$host
ktadd -k $kt hbase/$host
quit
EOF

}

#
# Setup to run on KDC
#
kadmin_setup() {
  kmasterpass=$1
  kadmpass=$2

  # Initialize the kerberos database
  /usr/kerberos/sbin/kdb5_util create -s -P ${kmasterpass}
  service krb5kdc start
  service kadmin start
  sleep 1

  # add standard principals
  /usr/kerberos/sbin/kadmin.local <<EOF 
add_principal -pw $kadmpass kadmin/admin
add_principal -pw $kadmpass hadoop/admin
add_principal -pw had00p hclient
quit
EOF

}


# up file-max
sysctl -w fs.file-max=32768

# up ulimits
echo "root soft nofile 32768" >> /etc/security/limits.conf
echo "root hard nofile 32768" >> /etc/security/limits.conf

# up epoll limits; ok if this fails, only valid for kernels 2.6.27+
sysctl -w fs.epoll.max_user_instances=32768 > /dev/null 2>&1

[ ! -f /etc/hosts ] &&  echo "127.0.0.1 localhost" > /etc/hosts
echo "$HOST_IP $HOSTNAME" >> /etc/hosts

# note kdc hostname
echo -n "$MASTER_HOST" > /etc/tm-kdc-hostname

# Extra packages

if [ "$EXTRA_PACKAGES" != "" ] ; then
  # format should be <repo-descriptor-URL> <package1> ... <packageN>
  pkg=( $EXTRA_PACKAGES )
  wget -nv -O /etc/yum.repos.d/user.repo ${pkg[0]}
  yum -y update yum
  yum -y install ${pkg[@]:1}
fi

# Security setup
# all servers need krb5 libraries
yum -y install krb5-libs jakarta-commons-daemon-jsvc
ln -s /usr/bin/jsvc $HADOOP_HOME/bin
adduser hadoop
if [ "$IS_MASTER" = "true" ]; then
  yum -y install krb5-server
  cat > /var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@HADOOP.LOCALDOMAIN    *
EOF

  cat > /var/kerberos/krb5kdc/kdc.conf <<EOF
[kdcdefaults]
 v4_mode = nopreauth
 kdc_ports = 0
 kdc_tcp_ports = 88

[realms]
 HADOOP.LOCALDOMAIN = {
  master_key_type = des3-hmac-sha1
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm
  max_life = 1d 0h 0m 0s
  max_renewable_life = 7d 0h 0m 0s
  default_principal_flags = +preauth
 }
EOF
fi

cat > /etc/krb5.conf <<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = HADOOP.LOCALDOMAIN
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 forwardable = yes
 proxiable = yes
 udp_preference_limit = 1
 extra_addresses = 127.0.0.1
 kdc_timesync = 1
 ccache_type = 4

[realms]
 HADOOP.LOCALDOMAIN = {
  kdc = ${MASTER_HOST}:88
  admin_server = ${MASTER_HOST}:749
 }

[domain_realm]
 localhost = HADOOP.LOCALDOMAIN
 .compute-1.internal = HADOOP.LOCALDOMAIN
 .internal = HADOOP.LOCALDOMAIN
 internal = HADOOP.LOCALDOMAIN

[appdefaults]
 pam = {
   debug = false
   ticket_lifetime = 36000
   renew_lifetime = 36000
   forwardable = true
   krb4_convert = false
 }

[login]
	krb4_convert = true
	krb4_get_tickets = false
EOF

# TODO: generate these from pwgen and pass throug
KDC_MASTER_PASS="EiSei0Da"
KDC_ADMIN_PASS="Chohpet6"

if [ "$IS_MASTER" = "true" ]; then
  kadmin_setup $KDC_MASTER_PASS $KDC_ADMIN_PASS
fi

# add principals for this host
keytab="$HADOOP_HOME/conf/nn.keytab"
# create local principals and keytab
add_client "hadoop/admin" $KDC_ADMIN_PASS $keytab $HOSTNAME
chown hadoop:hadoop $keytab

# Ganglia

if [ "$IS_MASTER" = "true" ]; then
  sed -i -e "s|\( *mcast_join *=.*\)|#\1|" \
      -e "s|\( *bind *=.*\)|#\1|" \
      -e "s|\( *mute *=.*\)|  mute = yes|" \
      -e "s|\( *location *=.*\)|  location = \"master-node\"|" \
      /etc/gmond.conf
  mkdir -p /mnt/ganglia/rrds
  chown -R ganglia:ganglia /mnt/ganglia/rrds
  rm -rf /var/lib/ganglia; cd /var/lib; ln -s /mnt/ganglia ganglia; cd
  service gmond start
  service gmetad start
  apachectl start
else
  sed -i -e "s|\( *mcast_join *=.*\)|#\1|" \
      -e "s|\( *bind *=.*\)|#\1|" \
      -e "s|\(udp_send_channel {\)|\1\n  host=$MASTER_HOST|" \
      /etc/gmond.conf
  service gmond start
fi

# Reformat sdb as xfs
umount /mnt
mkfs.xfs -f /dev/sdb
mount -o noatime /dev/sdb /mnt
#mkdir -p /mnt/hadoop/dfs/name
mkdir -p /mnt/hadoop/dfs/data

# Probe for additional instance volumes

# /dev/sdb as /mnt is always set up by base image
DFS_NAME_DIR="/mnt/hadoop/dfs/name"
DFS_DATA_DIR="/mnt/hadoop/dfs/data"
i=2
for d in c d e f g h i j k l m n o p q r s t u v w x y z; do
  m="/mnt${i}"
  mkdir -p $m
  mkfs.xfs -f /dev/sd${d}
  if [ $? -eq 0 ] ; then
    mount -o noatime /dev/sd${d} $m > /dev/null 2>&1
    if [ $i -lt 3 ] ; then # no more than two namedirs
      DFS_NAME_DIR="${DFS_NAME_DIR},${m}/hadoop/dfs/name"
    fi
    mkdir -p ${m}/hadoop/dfs/data
	chown $HADOOP_SECURE_DN_USER:root ${m}/hadoop/dfs/data
    DFS_DATA_DIR="${DFS_DATA_DIR},${m}/hadoop/dfs/data"
    i=$(( i + 1 ))
  fi
done

# Hadoop configuration
cat >> $HADOOP_HOME/conf/hadoop-env.sh <<EOF
export HADOOP_OPTS="$HADOOP_OPTS -Djavax.security.auth.useSubjectCredsOnly=false"
export HADOOP_SECURE_DN_USER=hadoop
EOF

( cd /usr/local && ln -s $HADOOP_HOME hadoop ) || true
cat > $HADOOP_HOME/conf/core-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>hadoop.tmp.dir</name>
  <value>/mnt/hadoop</value>
</property>
<property>
  <name>fs.default.name</name>
  <value>hdfs://$MASTER_HOST:8020</value>
</property>
<property>
  <name>hadoop.security.authorization</name>
  <value>true</value>
</property>
<property>
  <name>hadoop.security.authentication</name>
  <value>kerberos</value>
</property>
</configuration>
EOF
cat > $HADOOP_HOME/conf/hdfs-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>fs.default.name</name>
  <value>hdfs://$MASTER_HOST:8020</value>
</property>
<property>
  <name>dfs.name.dir</name>
  <value>$DFS_NAME_DIR</value>
</property>
<property>
  <name>dfs.data.dir</name>
  <value>$DFS_DATA_DIR</value>
</property>
<property>
  <name>dfs.replication</name>
  <value>2</value>
</property>
<property>
  <name>dfs.support.append</name>
  <value>false</value>
</property>
<property>
  <name>dfs.datanode.handler.count</name>
  <value>10</value>
</property>
<property>
  <name>dfs.datanode.max.xcievers</name>
  <value>10000</value>
</property>
<!-- security configuration -->
<property>
  <name>dfs.https.port</name>
  <value>50475</value>
</property>
<property>
  <name>dfs.namenode.keytab.file</name>
  <value>$HADOOP_HOME/conf/nn.keytab</value>
</property>	
<property>
  <name>dfs.namenode.kerberos.principal</name>
  <value>hadoop/$MASTER_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>dfs.namenode.kerberos.https.principal</name>
  <value>hadoop/$MASTER_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>dfs.secondary.https.port</name>
  <value>50495</value>
</property>	
<property>
  <name>dfs.secondary.namenode.keytab.file</name>
  <value>$HADOOP_HOME/conf/nn.keytab</value>
</property>	
<property>
  <name>dfs.secondary.namenode.kerberos.principal</name>
  <value>hadoop/$MASTER_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>dfs.secondary.namenode.kerberos.https.principal</name>
  <value>hadoop/$MASTER_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>dfs.datanode.keytab.file</name>
  <value>$HADOOP_HOME/conf/nn.keytab</value>
</property>	
<property>
  <name>dfs.datanode.kerberos.principal</name>
  <value>hadoop/$HOSTNAME@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>dfs.datanode.kerberos.https.principal</name>
  <value>hadoop/$HOSTNAME@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>dfs.block.access.token.enable</name>
  <value>true</value>
</property>
</configuration>
EOF
cat > $HADOOP_HOME/conf/mapred-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>mapred.job.tracker</name>
  <value>$MASTER_HOST:8021</value>
</property>
<property>
  <name>io.compression.codecs</name>
  <value>org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.BZip2Codec,com.hadoop.compression.lzo.LzoCodec,com.hadoop.compression.lzo.LzopCodec</value>
</property>
<property>
  <name>mapreduce.jobtracker.keytab.file</name>
  <value>$HADOOP_HOME/conf/nn.keytab</value>
</property>	
<property>
  <name>mapreduce.jobtracker.kerberos.principal</name>
  <value>hadoop/$MASTER_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>mapreduce.jobtracker.kerberos.https.principal</name>
  <value>hadoop/$MASTER_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>mapreduce.tasktracker.keytab.file</name>
  <value>$HADOOP_HOME/conf/nn.keytab</value>
</property>	
<property>
  <name>mapreduce.tasktracker.kerberos.principal</name>
  <value>hadoop/$HOSTNAME@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>mapreduce.tasktracker.kerberos.https.principal</name>
  <value>hadoop/$HOSTNAME@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>mapreduce.jobtracker.system.dir</name>
  <value>/tmp/mapred/system</value>
</property>
<property>
  <name>mapreduce.jobtracker.staging.root.dir</name>
  <value>/user</value>
</property>
<property>
  <name>mapred.temp.dir</name>
  <value>/tmp/mapred/temp</value>
</property>
<property>
  <name>mapred.acls.enabled</name>
  <value>true</value>
</property>
<property>
  <name>mapreduce.job.acl-modify-job</name>
  <value></value>
</property>
<property>
  <name>mapreduce.job.acl-view-job</name>
  <value></value>
</property>
<property>
  <name>io.compression.codec.lzo.class</name>
  <value>com.hadoop.compression.lzo.LzoCodec</value>
</property>
<property>
  <name>mapred.map.tasks</name>
  <value>4</value>
</property>
<property>
  <name>mapred.map.tasks.speculative.execution</name>
  <value>false</value>
</property>
<property>
  <name>mapred.child.java.opts</name>
  <value>-Xmx512m -XX:+UseCompressedOops</value>
</property>
</configuration>
EOF
# Add JVM options
cat >> $HADOOP_HOME/conf/hadoop-env.sh <<EOF
export HADOOP_OPTS="$HADOOP_OPTS -XX:+UseCompressedOops"
EOF
# Update classpath to include HBase jars and config
cat >> $HADOOP_HOME/conf/hadoop-env.sh <<EOF
export HADOOP_CLASSPATH="$HBASE_HOME/hbase-${HBASE_VERSION}.jar:$HBASE_HOME/lib/AgileJSON-2009-03-30.jar:$HBASE_HOME/lib/json.jar:$HBASE_HOME/lib/zookeeper-3.3.0.jar:$HBASE_HOME/conf"
EOF
# Configure Hadoop for Ganglia
cat > $HADOOP_HOME/conf/hadoop-metrics.properties <<EOF
dfs.class=org.apache.hadoop.metrics.ganglia.GangliaContext
dfs.period=10
dfs.servers=$MASTER_HOST:8649
jvm.class=org.apache.hadoop.metrics.ganglia.GangliaContext
jvm.period=10
jvm.servers=$MASTER_HOST:8649
mapred.class=org.apache.hadoop.metrics.ganglia.GangliaContext
mapred.period=10
mapred.servers=$MASTER_HOST:8649
EOF

# HBase configuration

( cd /usr/local && ln -s $HBASE_HOME hbase ) || true
cat > $HBASE_HOME/conf/hbase-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>hbase.rootdir</name>
  <value>hdfs://$MASTER_HOST:8020/hbase</value>
</property>
<property>
  <name>hbase.cluster.distributed</name>
  <value>true</value>
</property>
<property>
  <name>hbase.regions.server.count.min</name>
  <value>$NUM_SLAVES</value>
</property>
<property>
  <name>hbase.zookeeper.quorum</name>
  <value>$ZOOKEEPER_QUORUM</value>
</property>
<property>
  <name>hadoop.security.authorization</name>
  <value>true</value>
</property>
<property>
  <name>hadoop.security.authentication</name>
  <value>kerberos</value>
</property>
<property>
  <name>hbase.regionserver.handler.count</name>
  <value>100</value>
</property>
<property>
  <name>hbase.regionserver.flushlogentries</name>
  <value>100</value>
</property>
<property>
  <name>hfile.block.cache.size</name>
  <value>0.3</value>
</property>
<property>
  <name>hbase.regionserver.global.memstore.upperLimit</name>
  <value>0.3</value>
</property>
<property>
  <name>hbase.regionserver.global.memstore.lowerLimit</name>
  <value>0.25</value>
</property>
<property>
  <name>hbase.hregion.memstore.block.multiplier</name>
  <value>4</value>
</property>
<property>
  <name>hbase.hstore.blockingStoreFiles</name>
  <value>15</value>
</property>
<property>
  <name>dfs.replication</name>
  <value>2</value>
</property>
<property>
  <name>dfs.support.append</name>
  <value>false</value>
</property>
<property>
  <name>dfs.client.block.write.retries</name>
  <value>20</value>
</property>
<property>
  <name>dfs.datanode.socket.write.timeout</name>
  <value>0</value>
</property>
<property>
  <name>zookeeper.session.timeout</name>
  <value>60000</value>
</property>
<property>
  <name>hbase.tmp.dir</name>
  <value>/mnt/hbase</value>
</property>
<!-- Security RPC setup -->
<property>
  <name>hbase.master.keytab.file</name>
  <value>$HADOOP_HOME/conf/nn.keytab</value>
</property>	
<property>
  <name>hbase.master.kerberos.principal</name>
  <value>hbase/_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>hbase.master.kerberos.https.principal</name>
  <value>hbase/_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>hbase.regionserver.keytab.file</name>
  <value>$HADOOP_HOME/conf/nn.keytab</value>
</property>	
<property>
  <name>hbase.regionserver.kerberos.principal</name>
  <value>hbase/_HOST@HADOOP.LOCALDOMAIN</value>
</property>
<property>
  <name>hbase.regionserver.kerberos.https.principal</name>
  <value>hbase/_HOST@HADOOP.LOCALDOMAIN</value>
</property>
</configuration>
EOF

cat > $HBASE_HOME/conf/hadoop-policy.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>security.client.protocol.acl</name>
    <value>*</value>
  </property>
  <property>
    <name>security.admin.protocol.acl</name>
    <value>*</value>
  </property>
  <property>
    <name>security.masterregion.protocol.acl</name>
    <value>*</value>
  </property>
</configuration>
EOF
# link in hadoop config (for dfs client)
ln -s $HADOOP_HOME/conf/core-site.xml $HBASE_HOME/conf/
ln -s $HADOOP_HOME/conf/hdfs-site.xml $HBASE_HOME/conf/
ln -s $HADOOP_HOME/conf/mapred-site.xml $HBASE_HOME/conf/
# Override JVM options
cat >> $HBASE_HOME/conf/hbase-env.sh <<EOF
export HBASE_MASTER_OPTS="-Xmx1000m -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -XX:+DoEscapeAnalysis -XX:+AggressiveOpts -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/mnt/hbase/logs/hbase-master-gc.log"
export HBASE_REGIONSERVER_OPTS="-Xmx4000m -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=88 -XX:NewSize=128m -XX:MaxNewSize=128m -XX:+DoEscapeAnalysis -XX:+AggressiveOpts -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/mnt/hbase/logs/hbase-regionserver-gc.log"
EOF
# Configure log4j
sed -i -e 's/hadoop.hbase=DEBUG/hadoop.hbase=INFO/g' \
    $HBASE_HOME/conf/log4j.properties
# Configure HBase for Ganglia
cat > $HBASE_HOME/conf/hadoop-metrics.properties <<EOF
dfs.class=org.apache.hadoop.metrics.ganglia.GangliaContext
dfs.period=10
dfs.servers=$MASTER_HOST:8649
hbase.class=org.apache.hadoop.metrics.ganglia.GangliaContext
hbase.period=10
hbase.servers=$MASTER_HOST:8649
jvm.class=org.apache.hadoop.metrics.ganglia.GangliaContext
jvm.period=10
jvm.servers=$MASTER_HOST:8649
EOF

mkdir -p /mnt/hadoop/logs /mnt/hbase/logs
# FIXME: tighten ownership/perms
chmod 777 /mnt/hadoop/logs

if [ "$IS_MASTER" = "true" ]; then
  # only format on first boot
  [ ! -e /mnt/hadoop/dfs/name ] && "$HADOOP_HOME"/bin/hadoop namenode -format
  "$HADOOP_HOME"/bin/hadoop-daemon.sh start namenode
  "$HADOOP_HOME"/bin/hadoop-daemon.sh start jobtracker
  # "$HBASE_HOME"/bin/hbase-daemon.sh start master
else
    if [ "$IS_AUX" != "true" ]; then
	"$HADOOP_HOME"/bin/hadoop-daemon.sh start datanode
  # "$HBASE_HOME"/bin/hbase-daemon.sh start regionserver
	"$HADOOP_HOME"/bin/hadoop-daemon.sh start tasktracker
    fi
fi

rm -f /var/ec2/ec2-run-user-data.*
