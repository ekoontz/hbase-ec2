class tm {
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

  file { "/opt/hbase.tar.gz":
    owner => ec2-user,
    group => ec2-user,
    mode => 750,
    ignore => ".git*",
    source => "puppet://puppet/files/hbase.tar.gz"
  }

  file { "/opt/hadoop.sh":
    owner => ec2-user,
    group => ec2-user,
    mode => 755,
    ignore => ".git*",
    source => "puppet://puppet/files/hadoop.sh"
  }

  exec { "/opt/hadoop.sh":
    user => "ec2-user",
    cwd => "/opt",
    path => ["/opt/jre1.6.0_22/bin","/bin","/usr/bin","/usr/sbin"],
    subscribe => File["/opt/hadoop-common.tar.gz","/opt/hadoop.sh","/opt/jre.tar.gz"],
    environment => ["JAVA_HOME=/opt/jre1.6.0_22"],
    refreshonly => true
  }

}

include tm
