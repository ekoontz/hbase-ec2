file { "/etc/hosts":
  owner => root,
  group => root,
  mode => 644,
  source => "puppet://puppet/files/hosts"
}
file { "/opt":
  owner => ec2-user
}
file { "/opt/jre.tar.gz":
  owner => ec2-user,
  group => ec2-user,
  mode => 755,
  ignore => ".git*",
  source => "puppet://puppet/files/jre.tar.gz"
}
file { "/opt/hadoop-common.tar.gz":
  owner => ec2-user,
  group => ec2-user,
  mode => 750,
  ignore => ".git*",
  source => "puppet://puppet/files/hadoop-common.tar.gz"
}

exec { "tar -xzf /opt/jre.tar.gz":
  user => "ec2-user",
  group => "ec2-user",
  cwd => "/opt",
  creates => "/opt/jre1.6.0_22",
  path => ["/bin","/usr/bin"],
  onlyif => "test -f /opt/jre.tar.gz", 
  subscribe => File["/opt/jre.tar.gz"]
}	 
exec { "tar -xzf /opt/hadoop-common.tar.gz":
  user => ec2-user,
  group => ec2-user,
  cwd => "/opt",
  creates => "/opt/hadoop-common",
  path => ["/bin","/usr/bin"],
  onlyif => "test -f /opt/hadoop-common.tar.gz", 
  subscribe => File["/opt/hadoop-common.tar.gz"] 
}	 

file { "/opt/m2.tar.gz":
  owner => ec2-user,
  group => ec2-user,
  mode => 750,
  ignore => ".git*",
  source => "puppet://puppet/files/m2.tar.gz"
}
exec { "tar -xzf /opt/m2.tar.gz":
  user => "ec2-user",
  group => "ec2-user",
  cwd => "/home/ec2-user",
  creates => "/home/ec2-user/.m2",
  path => ["/bin","/usr/bin"],
  onlyif => "test -f /opt/m2.tar.gz", 
  subscribe => File["/opt/m2.tar.gz"]
}	 
file { "/opt/hbase.tar.gz":
  owner => ec2-user,
  group => ec2-user,
  mode => 750,
  ignore => ".git*",
  source => "puppet://puppet/files/hbase.tar.gz"
}
exec { "tar -xzf /opt/hbase.tar.gz":
  user => ec2-user,
  group => ec2-user,
  cwd => "/opt",
  creates => "/opt/hbase",
  path => ["/bin","/usr/bin"],
  onlyif => "test -f /opt/hbase.tar.gz", 
  subscribe => File["/opt/hbase.tar.gz"]
}	 
file { "/opt/hadoop-common/logs":
  mode => 755,
  owner => ec2-user
}
file { "/opt/hbase/logs":
  mode => 755,
  owner => ec2-user
}

class zookeeper {
  file { "/opt/zookeeper.tar.gz":
    owner => ec2-user,
    group => ec2-user,
    mode => 750,
    ignore => ".git*",
    source => "puppet://puppet/files/zookeeper.tar.gz"
  }
  exec { "tar -xzf /opt/zookeeper.tar.gz":
    user => ec2-user,
    group => ec2-user,
    cwd => "/opt",
    creates => "/opt/zookeeper",
    path => ["/bin","/usr/bin"],
    onlyif => "test -f /opt/zookeeper.tar.gz", 
    subscribe => File["/opt/zookeeper.tar.gz"]
  }	 
  exec { "mkdir -p /tmp/zk-data":
    user => ec2-user,
    group => ec2-user,
    creates => "/tmp/zk-data",
    path => ["/bin","/usr/bin"]
  }	 
  file { "/etc/init.d/zookeeper-quorum-member":
    mode => 755,
    source => "puppet://puppet/files/zookeeper-quorum-member"
  }
  service { "zookeeper-quorum-member":
    ensure => true
  }
}

class datanode {
  file { "/etc/init.d/hadoop-datanode":
    mode => 755,
    source => "puppet://puppet/files/hadoop-datanode"
  }
  service { "hadoop-datanode":
    ensure => true
  }
}

class tasktracker {
  file { "/etc/init.d/hadoop-tasktracker":
    mode => 755,
    source => "puppet://puppet/files/hadoop-tasktracker"
  }
  service { "hadoop-tasktracker":
    ensure => true
  }
}

class jobtracker {
  file { "/etc/init.d/hadoop-jobtracker":
    mode => 755,
    source => "puppet://puppet/files/hadoop-jobtracker"
  }
  service { "hadoop-jobtracker":
    ensure => true
  }
}

class namenode {
  exec { "/opt/hadoop-common/bin/hadoop namenode -format":
      user => ec2-user,
      group => ec2-user,
      creates => "/tmp/hadoop-ec2-user/dfs/name",
      environment => ["JAVA_HOME=/opt/jre1.6.0_22"]
  }
  file { "/etc/init.d/hadoop-namenode":
    mode => 755,
    source => "puppet://puppet/files/hadoop-namenode"
  }
  service { "hadoop-namenode":
    ensure => true
  }
}

class regionserver {
  file { "/etc/init.d/hbase-regionserver":
    mode => 755,
    source => "puppet://puppet/files/hbase-regionserver"
  }
  service { "hbase-regionserver":
    ensure => true
  }
}

class master {
  file { "/etc/init.d/hbase-master":
    mode => 755,
    source => "puppet://puppet/files/hbase-master"
  }
  service { "hbase-master":
    ensure => true
  }
}

node "puppet" {
  include jobtracker
  include namenode
  include datanode
  include tasktracker
  include zookeeper
  include master
  include regionserver
}

