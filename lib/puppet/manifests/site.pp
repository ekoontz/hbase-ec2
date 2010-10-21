class tm {

  file { "/opt/hadoop-common.tar.gz":
    owner => ec2-user,
    group => ec2-user,
    mode => 750,
    ignore => ".git*",
    source => "puppet://puppet/files/hadoop-common.tar.gz"
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
    path => ["/opt/jdk1.6.0_22/bin","/bin","/usr/bin","/usr/sbin"],
    subscribe => File["/opt/hadoop-common.tar.gz","/opt/hadoop.sh","/opt/jdk.tar.gz"],
    environment => ["JAVA_HOME=/opt/jdk1.6.0_22"],
    refreshonly => true
  }

  file { "/opt/jdk.tar.gz":
    owner => ec2-user,
    group => ec2-user,
    mode => 755,
    ignore => ".git*",
    source => "puppet://puppet/files/jdk.tar.gz"
  }

  exec { "tar xfz /opt/jdk.tar.gz":
    user => "ec2-user",
    cwd => "/opt",
    path => ["/bin","/usr/bin","/usr/sbin"],
    subscribe => File["/opt/jdk.tar.gz"],
    refreshonly => true
  }


}

include tm
