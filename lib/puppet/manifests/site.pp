class ec2 {

  file { "/opt/jre.tar.gz":
    owner => ec2-user,
    group => ec2-user,
    mode => 755,
    ignore => ".git*",
    source => "puppet://puppet/files/jre.tar.gz"
  }

  exec { "tar -xzf /opt/jre.tar.gz":
    cwd => "/opt",
    creates => "/opt/jre1.6.0_22",
    path => ["/bin","/usr/bin"],
    onlyif => "test -f /opt/jre.tar.gz", 
    subscribe => File["/opt/jre.tar.gz"]
  }	 

  file { "/opt/hadoop-common.tar.gz":
    owner => ec2-user,
    group => ec2-user,
    mode => 750,
    ignore => ".git*",
    source => "puppet://puppet/files/hadoop-common.tar.gz"
  }

  exec { "tar -xzf /opt/hadoop-common.tar.gz":
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
    cwd => "/opt",
    creates => "/opt/hbase",
    path => ["/bin","/usr/bin"],
    onlyif => "test -f /opt/hbase.tar.gz", 
    subscribe => File["/opt/hbase.tar.gz"]
  }	 

  file { "/etc/init.d/hadoop-datanode":
    mode => 755,
    source => "puppet://puppet/files/hadoop-datanode"
  }
  service { "datanode":
    ensure => true,
    start => "service hadoop-datanode start",
    stop => "service hadoop-datanode stop",
    provider => "init",
    pattern => "datanode"
  }

  file { "/etc/init.d/hbase-regionserver":
    mode => 755,
    source => "puppet://puppet/files/hbase-regionserver"
  }
  service { "regionserver":
    ensure => true,
    start => "service hbase-regionserver start",
    stop => "service hbase-regionserver stop",
    provider => "init",
    pattern => "regionserver"
  }
 
}

include ec2


