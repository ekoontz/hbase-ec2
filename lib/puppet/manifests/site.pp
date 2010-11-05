
class base {
  yumrepo { "epel":
    baseurl => "http://download.fedora.redhat.com/pub/epel/5/x86_64/",
    descr => "Extra Packages for Enterprise Linux",
    enabled => 1,
    gpgcheck => 0
  }
  file { "/etc/hosts":
    owner => root,
    group => root,
    mode => 644,
    source => "puppet://puppet/files/hosts"
  }
}

#this might not be needed anymore...
#exec { "cat /etc/sudoers | perl -pe 's/^(Defaults\s+requiretty)/#Defaults requiretty/' > /tmp/puppetfiles/sudoers":
#    onlyif => "test ! -f /tmp/puppetfiles/sudoers",
#    path => ["/bin","/usr/bin"]
#}
#..nor this.
#file { "/etc/sudoers":
#  owner => root,
#  group => root,
#  mode => 400,
#  source => "puppet://puppet/files/sudoers",
#  backup => ".sudoers-bak"
#}

class install_runtime {
  include base

  file { "/opt":
    owner => ec2-user,
    mode => 755,
    group => wheel
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
}

class zookeeper {
  include install_runtime
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
    ensure => true,
    pattern => "zookeeper"
  }
}

class datanode {
  include install_runtime
  file { "/etc/init.d/hadoop-datanode":
    mode => 755,
    source => "puppet://puppet/files/hadoop-datanode"
  }
  service { "hadoop-datanode":
    ensure => true,
    pattern => "namenode"
  }
}

class tasktracker {
  include install_runtime
  file { "/etc/init.d/hadoop-tasktracker":
    mode => 755,
    source => "puppet://puppet/files/hadoop-tasktracker"
  }
  service { "hadoop-tasktracker":
    ensure => true,
    pattern => "tasktracker"
  }
}

class jobtracker {
  include install_runtime
  file { "/etc/init.d/hadoop-jobtracker":
    mode => 755,
    source => "puppet://puppet/files/hadoop-jobtracker"
  }
  service { "hadoop-jobtracker":
    ensure => true,
    pattern => "jobtracker"
  }
}

class namenode {
  include install_runtime
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
    ensure => true,
    pattern => "namenode"
  }
}

class regionserver {
  include install_runtime
  file { "/etc/init.d/hbase-regionserver":
    mode => 755,
    source => "puppet://puppet/files/hbase-regionserver"
  }
  service { "hbase-regionserver":
    ensure => true,
    pattern => "regionserver"
  }
}

class master {
  include install_runtime
  file { "/etc/init.d/hbase-master":
    mode => 755,
    source => "puppet://puppet/files/hbase-master"
  }
  service { "hbase-master":
    ensure => true,
    pattern => "master"
  }
}

class devtools {
    include base
# note that we don't 'include install_runtime' here since
# the 'install_runtime' requires artifacts that we build here
    include sources

    package {"git": ensure => installed, require => Yumrepo["epel"] }
    package {"emacs": ensure => installed, require => Yumrepo["epel"] }
    package {"ruby-rdoc": ensure => installed, require => Yumrepo["epel"] }
 
   exec { "wget_jdk":
      command => "wget http://ekoontz-tarballs.s3.amazonaws.com/jdk1.6.0_22.tar.gz",
      user => ec2-user,
      group => ec2-user,
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/jdk1.6.0_22.tar.gz",
      path => ["/bin","/usr/bin"],
      notify => Exec["untar_jdk"]
    }
    exec { "untar_jdk":
      command => "tar -xzf /home/ec2-user/jdk1.6.0_22.tar.gz",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/jdk1.6.0_22",
      path => ["/bin","/usr/bin"],
      subscribe => Exec["wget_jdk"]
    }	 
 
   exec { "wget http://ekoontz-tarballs.s3.amazonaws.com/apache-maven-3.0-bin.tar.gz":
      user => ec2-user,
      group => ec2-user,
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/apache-maven-3.0-bin.tar.gz",
      path => ["/bin","/usr/bin"]
    }
    exec { "tar -xzf /home/ec2-user/apache-maven-3.0-bin.tar.gz":
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/apache-maven-3.0",
      path => ["/bin","/usr/bin"],
      onlyif => "test -f /home/ec2-user/apache-maven-3.0-bin.tar.gz"
    }	 

    exec { "wget http://ekoontz-tarballs.s3.amazonaws.com/apache-ant-1.8.1-bin.tar.bz2":
      user => ec2-user,
      group => ec2-user,
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/apache-ant-1.8.1-bin.tar.bz2",
      path => ["/bin","/usr/bin"]
    }
    exec { "tar -xjf /home/ec2-user/apache-ant-1.8.1-bin.tar.bz2":
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/apache-ant-1.8.1",
      path => ["/bin","/usr/bin"],
      onlyif => "test -f /home/ec2-user/apache-ant-1.8.1-bin.tar.bz2"
    }	 

    exec { "wget http://ekoontz-tarballs.s3.amazonaws.com/jre-6u22-linux-x64.bin":
      user => ec2-user,
      group => ec2-user,
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/jre-6u22-linux-x64.bin",
      path => ["/bin","/usr/bin"]
    }

    exec { "sh_jre":
      command => "sh jre-6u22-linux-x64.bin",
      user => ec2-user,
      group => ec2-user,
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/jre1.6.0_22",
      path => ["/bin","/usr/bin"],
      notify => Exec["tarball_jre"]
    }

    exec {"tarball_jre":
	command => "tar  --exclude=\".git*\" -czf /tmp/puppetfiles/jre.tar.gz jre1.6.0_22",
        cwd => "/home/ec2-user",
        user => "ec2-user",
        group => "ec2-user",
        path => ["/bin","/usr/bin"],
        subscribe => Exec["sh_jre"]
    }

    exec { "wget http://ekoontz-tarballs.s3.amazonaws.com/m2.tar.gz -o /tmp/puppetfiles/m2.tar.gz":
      user => ec2-user,
      group => ec2-user,
      cwd => "/home/ec2-user",
      creates => "/tmp/puppetfiles/m2.tar.gz",
      path => ["/bin","/usr/bin"]
    }
    exec { "tar -xzf /tmp/puppetfiles/m2.tar.gz":
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/.m2",
      path => ["/bin","/usr/bin"],
      onlyif => "test -f /home/ec2-user/m2.tar.gz"
    }	 
 }

 class sources {

    exec { "git clone git://github.com/ekoontz/hbase-ec2.git":
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/hbase-ec2"],
      path => ["/bin","/usr/bin"],
      notify => Exec["checkout_hbase_ec2_branch"]
    }            

    exec { "checkout_hbase_ec2_branch":
      command => "git checkout -b puppet || git checkout puppet",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user/hbase-ec2",
      onlyif => "test -x /usr/bin/git",
      path => ["/bin","/usr/bin"]
    }

    exec { "clone_hadoop":
      command => "git clone git://github.com/trendmicro/hadoop-common.git",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => "test -x /usr/bin/git",
      path => ["/bin","/usr/bin"],
      creates => "/home/ec2-user/hadoop-common",
      notify => Exec["checkout_append"],
    }            

    exec { "checkout_append":
      command => "git checkout -b yahoo-hadoop-0.20.104-append || git checkout yahoo-hadoop-0.20.104-append",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user/hadoop-common",
      onlyif => "test -x /usr/bin/git",
      path => ["/bin","/usr/bin"],
      subscribe => Exec["clone_hadoop"],
      notify => Exec["compile_hadoop"]
    }            


    exec { "clone_hbase":
      command => "git clone git://github.com/trendmicro/hbase.git",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/hbase"],
      path => ["/bin","/usr/bin"],
      notify => Exec["checkout_security"],
      creates => "/home/ec2-user/hbase"
    }            

    exec { "checkout_security":
      command => "git checkout -b security || git checkout security",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user/hbase",
      path => ["/bin","/usr/bin"],
      subscribe => Exec["clone_hbase"],
      notify => Exec["compile_hbase"]
    }            

    exec { "clone_zookeeper":
      command => "git clone git://github.com/apache/zookeeper.git",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/zookeeper"],
      path => ["/bin","/usr/bin"],
      creates => "/home/ec2-user/zookeeper",
      notify => Exec["compile_zookeeper"]
    }            

  class build {

    exec { "compile_zookeeper":
      subscribe => Exec["clone_zookeeper"],
      user => "ec2-user",
      group => "ec2-user",
      command => "ant compile",
      cwd => "/home/ec2-user/zookeeper",
      path => ["/home/ec2-user/jdk1.6.0_22/bin","/home/ec2-user/apache-ant-1.8.1/bin","/bin","/usr/bin"],
      environment => ["JAVA_HOME=/home/ec2-user/jdk1.6.0_22"],
      timeout => "-1",
      notify => Exec["tarball_zookeeper"]
    }

    exec {"tarball_zookeeper":
	command => "tar  --exclude=\".git*\" -czf /tmp/puppetfiles/zookeeper.tar.gz zookeeper",
        cwd => "/home/ec2-user",
        user => "ec2-user",
        group => "ec2-user",
        path => ["/bin","/usr/bin"],
        subscribe => Exec["compile_zookeeper"]
    }

    exec { "compile_hadoop":
      user => "ec2-user",
      group => "ec2-user",
      command => "ant compile",
      cwd => "/home/ec2-user/hadoop-common",
      onlyif => "test -x /home/ec2-user/apache-ant-1.8.1/bin/ant",
      path => ["/home/ec2-user/jdk1.6.0_22/bin","/home/ec2-user/apache-ant-1.8.1/bin","/bin","/usr/bin"],
      environment => ["JAVA_HOME=/home/ec2-user/jdk1.6.0_22"],
      timeout => "-1",
      notify => Exec["tarball_hadoop"]
    }

    exec {"tarball_hadoop":
	command => "tar  --exclude=\".git*\" -czf /tmp/puppetfiles/hadoop-common.tar.gz hadoop-common",
        cwd => "/home/ec2-user",
        user => "ec2-user",
        group => "ec2-user",
        path => ["/bin","/usr/bin"],
        subscribe => Exec["compile_hadoop"]
    }

    exec { "compile_hbase":
      user => "ec2-user",
      group => "ec2-user",
      command => "mvn compile",
      cwd => "/home/ec2-user/hbase",
      path => ["/home/ec2-user/jdk1.6.0_22/bin","/home/ec2-user/apache-maven-3.0/bin","/bin","/usr/bin"],
      environment => ["JAVA_HOME=/home/ec2-user/jdk1.6.0_22"],
      timeout => "-1",
      subscribe => Exec["checkout_security"],
      notify => Exec["tarball_hbase"]
    }

    exec {"tarball_hbase":
	command => "tar  --exclude=\".git*\" -czf /tmp/puppetfiles/hbase.tar.gz hbase",
        cwd => "/home/ec2-user",
        user => "ec2-user",
        group => "ec2-user",
        path => ["/bin","/usr/bin"],
        subscribe => Exec["compile_hbase"]
    }

}

class puppetmaster {
  include build
}

node "puppet" {
  include puppetmaster
  include install_runtime

#master daemons.
  include jobtracker
  include namenode
  include zookeeper
  include master

# we will economize by running all daemons (both masters and slaves)
# on the puppetmaster host.
  include datanode
  include regionserver
  include tasktracker
}

node default {
# slave daemons.
  include datanode
  include regionserver
  include tasktracker
}
