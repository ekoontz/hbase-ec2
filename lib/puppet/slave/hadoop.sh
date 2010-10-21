#!/bin/sh                                                                       
# hadoop.sh version 19: running as ec2-user in background.                      
#                                                                               
rm -rf /opt/hadoop-common
tar -C /opt -xzf /opt/hadoop-common.tar.gz
tar -C /opt -xzf /opt/jre.tar.gz

cd /opt/hadoop-common
bin/hadoop datanode >> /tmp/hadoop.err 2>&1 &



