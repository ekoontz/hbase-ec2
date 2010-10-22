#!/bin/sh

rm -rf /opt/hadoop-common
tar -C /opt -xzf /opt/jre.tar.gz
tar -C /opt -xzf /opt/hadoop-common.tar.gz
tar -C /opt -xzf /opt/hbase.tar.gz
tar -C /home/ec2-user -xzf /opt/m2.tar.gz

cd /opt/hadoop-common
bin/hadoop datanode >> /tmp/hadoop.err 2>&1 &

cd /opt/hbase
bin/hbase regionserver start >> /tmp/hbase.err 2>&1 &
