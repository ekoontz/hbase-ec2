
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

class install_runtime {
  include base
  
  file { "/etc/sudoers":
    owner => root,
    group => root,
    mode => 440,
    source => "puppet://puppet/files/sudoers",
    backup => ".bak"
  }
  
  file { "/opt":
    owner => ec2-user,
    mode => 755,
    group => wheel
  }
  file { "/opt/jre1.6.0_22":
    owner => ec2-user,
    group => ec2-user,
    ignore => ['man'],
    source => "puppet://puppet/files/jre1.6.0_22",
    recurse => true
  }

  file { "/opt/hadoop-common":
    owner => ec2-user,
    group => ec2-user,
    ignore => [".git*",'src',"*.class",'jdiff','patches'],
    source => "puppet://puppet/files/hadoop-common",
    recurse => true,
    purge => true
  }

  file { "/opt/hbase":
    owner => ec2-user,
    group => ec2-user,
    ignore => [".git*",'src',"*.class"],
    source => "puppet://puppet/files/hbase",
    recurse => true,
    purge => true
  }

  file { "/opt/solr":
    owner => ec2-user,
    group => ec2-user,
    ignore => [".git*",'src',"*.class",'jdiff','patches'],
    source => "puppet://puppet/files/solr",
    recurse => true,
    purge => true
  }
  
  file { "/opt/hadoop-common/logs":
    mode => 755,
    owner => ec2-user
  }
  file { "/opt/hbase/logs":
    mode => 755,
    owner => ec2-user
  }

  file { "/opt/hadoop-common/conf/hdfs-site.xml":
    source => "puppet://puppet/files/hdfs-site.xml",
    mode => 644,
    owner => ec2-user
  }

  file { "/opt/hadoop-common/conf/mapred-site.xml":
    source => "puppet://puppet/files/mapred-site.xml",
    mode => 644,
    owner => ec2-user
  }

  file { "/opt/hbase/conf/hbase-site.xml":
    source => "puppet://puppet/files/hbase-site.xml",
    mode => 644,
    owner => ec2-user
  }
}

class zookeeper {
  include install_runtime
  file { "/opt/zookeeper":
    owner => ec2-user,
    group => ec2-user,
    ignore => [".git*",'src',"*.class",'docs'],
    source => "puppet://puppet/files/zookeeper",
    recurse => true
  }

  file { "/opt/zookeeper/conf/zoo.cfg":
    source => "puppet://puppet/files/zoo.cfg",
    mode => 644,
    owner => ec2-user
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
    subscribe => [ File["/opt/zookeeper/conf/zoo.cfg"] ],
    ensure => true,
    pattern => "zookeeper",
    enable => true
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
    pattern => "datanode",
    enable => true
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
    pattern => "tasktracker",
    enable => true
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
    pattern => "jobtracker",
    enable => true
  }
}

class namenode {
  include install_runtime
  exec { "/opt/hadoop-common/bin/hadoop namenode -format":
      user => ec2-user,
      group => ec2-user,
      creates => "/tmp/hadoop-ec2-user/dfs/name",
      environment => ["JAVA_HOME=/opt/jre1.6.0_22","HADOOP_CLASSPATH=/opt/hadoop-common/build/hadoop-core-0.20.104.3-append-SNAPSHOT.jar"]
  }
  file { "/etc/init.d/hadoop-namenode":
    mode => 755,
    source => "puppet://puppet/files/hadoop-namenode"
  }
  service { "hadoop-namenode":
    ensure => true,
    pattern => "namenode",
    enable => true
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
    pattern => "regionserver",
    enable => true
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
    pattern => "hbase-ec2-user-master",
    enable => true
  }
}

class devtools {
    include base
# note that we don't 'include install_runtime' here since
# the 'install_runtime' requires artifacts that we build here

    package {"git": ensure => installed}
    package {"emacs": ensure => installed}
    package {"ruby-rdoc": ensure => installed}
    package {"telnet": ensure => installed}
 
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
    exec { "untar_maven":
      command => "tar -xzf /home/ec2-user/apache-maven-3.0-bin.tar.gz",
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
    exec { "untar_ant":
      command => "tar -xjf /home/ec2-user/apache-ant-1.8.1-bin.tar.bz2",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      creates => "/home/ec2-user/apache-ant-1.8.1",
      path => ["/bin","/usr/bin"],
      onlyif => "test -f /home/ec2-user/apache-ant-1.8.1-bin.tar.bz2"
    }	 

    exec { "wget_jre":
      command => "wget http://ekoontz-tarballs.s3.amazonaws.com/jre-6u22-linux-x64.bin",
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
      subscribe => Exec["wget_jre"],
      notify => Exec["stage_jre"]
    }

    exec {"stage_jre":
	command => "cp -r -u jre1.6.0_22 /tmp/puppetfiles",
        cwd => "/home/ec2-user",
        user => "ec2-user",
        group => "ec2-user",
        path => ["/bin","/usr/bin"],
        subscribe => Exec["sh_jre"]
    }

    exec { "wget_m2":
      command => "wget http://ekoontz-tarballs.s3.amazonaws.com/m2.tar.gz -O /tmp/puppetfiles/m2.tar.gz",
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
      subscribe => Exec["wget_m2"]
    }	 

    include m2

}

 class sources {

    exec { "git clone git://github.com/ekoontz/hbase-ec2.git":
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/hbase-ec2"],
      path => ["/bin","/usr/bin"],
      notify => Exec["checkout_hbase_ec2"]
    }            

    exec { "checkout_hbase_ec2":
      command => "git checkout -b puppet || git checkout puppet",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user/hbase-ec2",
      onlyif => "test -x /usr/bin/git",
      path => ["/bin","/usr/bin"],
      notify => Exec["zk_conf"]
    }

    exec { "clone_hadoop":
      command => "git clone git://github.com/trendmicro/hadoop-common.git",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => "test -x /usr/bin/git",
      path => ["/bin","/usr/bin"],
      creates => "/home/ec2-user/hadoop-common",
      notify => Exec["checkout_hadoop_append"],
    }            

    exec { "checkout_hadoop_append":
      command => "git checkout origin/yahoo-hadoop-0.20.104-append",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user/hadoop-common",
      onlyif => "test -x /usr/bin/git",
      path => ["/bin","/usr/bin"],
      subscribe => Exec["clone_hadoop"]
      #, notify => Class["compile_hadoop"]
    }            

    exec { "clone_hbase":
      command => "git clone git://github.com/trendmicro/hbase.git",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/hbase"],
      path => ["/bin","/usr/bin"],
      notify => Exec["checkout_hbase_security"],
      creates => "/home/ec2-user/hbase"
    }            

    exec { "checkout_hbase_security":
      command => "git checkout origin/security",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user/hbase",
      path => ["/bin","/usr/bin"],
      subscribe => Exec["clone_hbase"]
      #,      notify => Exec["compile_hbase"]
    }            

    exec { "clone_zookeeper":
      command => "git clone git://github.com/apache/zookeeper.git",
      user => "ec2-user",
      group => "ec2-user",
      cwd => "/home/ec2-user",
      onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/zookeeper"],
      path => ["/bin","/usr/bin"],
      creates => "/home/ec2-user/zookeeper"
#,      notify => Exec["compile_zookeeper"]
    }            

    exec { "zk_conf":
      command => "cp /home/ec2-user/hbase-ec2/lib/puppet/zoo.cfg /tmp/puppetfiles",
      user => "ec2-user",
      group => "ec2-user",
      creates => "/tmp/puppetfiles/zoo.cfg",
      path => ["/bin"],
      notify => Exec["stage_zookeeper"]
    }
    exec { "hdfs_conf":
      command => "cp /home/ec2-user/hbase-ec2/lib/puppet/hdfs-site.xml /tmp/puppetfiles",
      user => "ec2-user",
      group => "ec2-user",
      creates => "/tmp/puppetfiles/hdfs-site.xml",
      path => ["/bin"],
      notify => Exec["stage_hadoop"]
    }
    exec { "mapred_conf":
      command => "cp /home/ec2-user/hbase-ec2/lib/puppet/mapred-site.xml /tmp/puppetfiles",
      user => "ec2-user",
      group => "ec2-user",
      creates => "/tmp/puppetfiles/mapred-site.xml",
      path => ["/bin"],
      notify => Exec["stage_hadoop"]
    }
    exec { "hbase_conf":
      command => "cp /home/ec2-user/hbase-ec2/lib/puppet/hbase-site.xml /tmp/puppetfiles",
      user => "ec2-user",
      group => "ec2-user",
      creates => "/tmp/puppetfiles/hbase-site.xml",
      path => ["/bin"],
      notify => Exec["stage_hbase"]
    }

 }

class lily_sources {
  package {"subversion": ensure => installed}
  exec { "solr":
    command => "git clone git://github.com/apache/solr.git",
    user => "ec2-user",
    group => "ec2-user",
    cwd => "/home/ec2-user",
    onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/solr"],
    path => ["/bin","/usr/bin"],
#    creates => "/home/ec2-user/solr",
    notify => Exec["checkout_solr_1_4_1"]
  }
  
  exec { "checkout_solr_1_4_1":
    command => "git checkout release-1.4.1",
    user => "ec2-user",
    group => "ec2-user",
    cwd => "/home/ec2-user/solr",
    onlyif => "test -x /usr/bin/git",
    path => ["/bin","/usr/bin"],
    subscribe => Exec["solr"],
    notify => Exec["compile_solr"]
  }

  exec { "lily":
    command => "svn co http://dev.outerthought.org/svn_public/outerthought_lilyproject/tags/RELEASE_0_2_1 lily",
    user => "ec2-user",
    group => "ec2-user",
    cwd => "/home/ec2-user",
    onlyif => ["test -x /usr/bin/git","test ! -d /home/ec2-user/lily"],
    path => ["/bin","/usr/bin"],
    creates => "/home/ec2-user/lily"
  }

  
}
 
class build {
   include devtools
   include sources
   include lily_sources
  
   exec { "compile_zookeeper":
     user => "ec2-user",
     group => "ec2-user",
     command => "ant jar",
     cwd => "/home/ec2-user/zookeeper",
     path => ["/home/ec2-user/jdk1.6.0_22/bin","/home/ec2-user/apache-ant-1.8.1/bin","/bin","/usr/bin"],
     environment => ["JAVA_HOME=/home/ec2-user/jdk1.6.0_22"],
     notify => Exec["stage_zookeeper"],
     subscribe => [ Exec["untar_jdk"],Exec["untar_ant"],Exec["clone_zookeeper"] ],
     refreshonly => true,
     creates => "/home/ec2-user/build/classes"
   }
   
   exec { "compile_hadoop":
     user => "ec2-user",
     group => "ec2-user",
     command => "ant jar",
     cwd => "/home/ec2-user/hadoop-common",
     path => ["/home/ec2-user/jdk1.6.0_22/bin","/home/ec2-user/apache-ant-1.8.1/bin","/bin","/usr/bin"],
     environment => ["JAVA_HOME=/home/ec2-user/jdk1.6.0_22"],
     notify => Exec["stage_hadoop"],
     subscribe => [ Exec["untar_jdk"],Exec["untar_ant"],Exec["checkout_hadoop_append"] ],
     refreshonly => true,
     creates => "/home/ec2-user/hadoop-common/build/classes"
   }

   exec { "compile_hbase":
     user => "ec2-user",
     group => "ec2-user",
     command => "mvn compile dependency:build-classpath -Dmdep.outputFile=target/cached_classpath.txt jar:jar",
     cwd => "/home/ec2-user/hbase",
     path => ["/home/ec2-user/jdk1.6.0_22/bin","/home/ec2-user/apache-maven-3.0/bin","/bin","/usr/bin"],
     environment => ["JAVA_HOME=/home/ec2-user/jdk1.6.0_22"],
     notify => Exec["stage_hbase"],
     subscribe => [ Exec["untar_jdk"],Exec["untar_maven"],Exec["untar_m2"],Exec["checkout_hbase_security"] ],
     refreshonly => true,
     creates => "/home/ec2-user/hbase/target/cached_classpath.txt"
   }

   exec {"compile_solr":
     user => "ec2-user",
     group => "ec2-user",
     command => "ant dist",
     cwd => "/home/ec2-user/solr",
     path => ["/home/ec2-user/jdk1.6.0_22/bin","/home/ec2-user/apache-ant-1.8.1/bin","/bin","/usr/bin"],
     environment => ["JAVA_HOME=/home/ec2-user/jdk1.6.0_22"],
     notify => Exec["stage_solr"],
     subscribe => [ Exec["untar_jdk"],Exec["untar_ant"],Exec["checkout_solr_1_4_1"] ],
     refreshonly => true,
     creates => "/home/ec2-user/solr/build"
   }
   
   include initscripts
}

class make_tarballs {
  include build

  exec {"stage_zookeeper":
     command => "cp -u -r zookeeper /tmp/puppetfiles",
     cwd => "/home/ec2-user",
     user => "ec2-user",
     group => "ec2-user",
     path => ["/bin","/usr/bin"],
     subscribe => Exec["compile_zookeeper"],
     refreshonly => true
   }
   
   exec {"stage_hadoop":
     command => "cp -u -r hadoop-common /tmp/puppetfiles",
     cwd => "/home/ec2-user",
     user => "ec2-user",
     group => "ec2-user",
     path => ["/bin","/usr/bin"],
     subscribe => Exec["compile_hadoop"],
     refreshonly => true
   }

  exec {"stage_hbase":
     command => "cp -u -r hbase /tmp/puppetfiles",
     cwd => "/home/ec2-user",
     user => "ec2-user",
     group => "ec2-user",
     path => ["/bin","/usr/bin"],
     subscribe => Exec["compile_hbase"],
     refreshonly => true
   }

  exec {"stage_solr":
     command => "cp -u -r solr /tmp/puppetfiles",
     cwd => "/home/ec2-user",
     user => "ec2-user",
     group => "ec2-user",
     path => ["/bin","/usr/bin"],
     subscribe => Exec["compile_solr"],
     refreshonly => true
   }


}


class initscripts {
  exec {"initscripts":
    command => "cp -u /home/ec2-user/hbase-ec2/lib/initscripts/* /tmp/puppetfiles",
    path => ["/bin"],
    user => "ec2-user",
    group => "ec2-user"
  }

  exec { "cat /etc/sudoers | perl -pe 's/^(Defaults\s+requiretty)/#Defaults requiretty/' > /tmp/puppetfiles/sudoers":
    onlyif => "test ! -f /tmp/puppetfiles/sudoers",
    path => ["/bin","/usr/bin"]
  }

}

 class puppetmaster {
   include make_tarballs
 }

 node "puppet" {
   include puppetmaster
   #master daemons.
   include jobtracker
   include namenode
   include zookeeper
   include master

# we will economize by running all daemons (both masters and slaves)
# on the puppetmaster host.
   include datanode
   include tasktracker
   include regionserver
}

class m2 {

   file { "/opt/m2.tar.gz":
     owner => ec2-user,
     group => ec2-user,
     mode => 750,
     source => "puppet://puppet/files/m2.tar.gz",
     notify => Exec["untar_m2"]
   }
   exec { "untar_m2":
     command => "tar -xzf /opt/m2.tar.gz",
     user => ec2-user,
     group => ec2-user,
     cwd => "/home/ec2-user",
     path => ["/bin","/usr/bin"],
     onlyif => "test -f /opt/m2.tar.gz", 
     subscribe => File["/opt/m2.tar.gz"],
     refreshonly => true
   }	 
}

node default {
# slave daemons.

  include m2
  
  include datanode
  include tasktracker
  include regionserver
}

