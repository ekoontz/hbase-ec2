class tm {

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

  service { "datanode":
    ensure => true,
    start => "sudo -u ec2-user /opt/datanode.sh start datanode",
    stop  => "sudo -u ec2-user /opt/datanode.sh stop datanode",
  }

  service { "regionserver":
    ensure => true,
    start => "sudo -u ec2-user /opt/regionserver.sh start regionserver",
    stop => "sudo -u ec2-user /opt/regionserver.sh stop regionserver"
  }
 
}

include tm

