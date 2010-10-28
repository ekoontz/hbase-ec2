#!/bin/sh

export JAVA_HOME=/opt/jre1.6.0_22
/opt/hadoop-common/bin/hadoop-daemon.sh $*
