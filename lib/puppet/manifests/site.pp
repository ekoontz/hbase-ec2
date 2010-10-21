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
  
#  exec { "rm -rf /opt/hadoop-common ; tar -C /opt -xzf /opt/hadoop-common.tar.gz":
    exec { "/opt/hadoop.sh":
    cwd => "/opt",
    path => ["/bin","/usr/bin","/usr/sbin"],
    subscribe => File["/opt/hadoop-common.tar.gz","/opt/hadoop.sh"],
    refreshonly => true
  }
  
}

include tm

