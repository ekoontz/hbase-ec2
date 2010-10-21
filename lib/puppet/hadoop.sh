#!/bin/sh
# hadoop.sh version 16: running as ec2-user.
#
rm -rf /opt/hadoop-common
tar -C /opt -xzf /opt/hadoop-common.tar.gz
cd /opt/hadoop-common
bin/hadoop datanode >> /tmp/hadoop.err 2>&1 &
