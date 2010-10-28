#!/bin/sh
# run on each slave machine after syncing with puppet.
cd /opt/hadoop-common
bin/hadoop datanode >> /tmp/hadoop.err 2>&1 &

cd /opt/hbase
bin/hbase regionserver start >> /tmp/hbase.err 2>&1 &
