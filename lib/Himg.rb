#!/usr/bin/env ruby

require 'net/ssh'
require 'net/scp'

require 'defaults.rb'

module Hadoop
  class Himg
    def initialize(options = {})
      options = {
        :hbase_roles => "master,rs",
        :hadoop_roles => "namenode,datanode",
        :zookeeper_role => "quorum",
        :dns => "server",
        :mongodb => "master",
        :git => "git@github.com/trendmicro",
        :kerberos_roles => "auth,tg",
        :domain => "foocluster.foofers.org",
        :image_creation_fn => lambda{|options|
          img_id = "abcd-0123"
          puts "ta-DAAH! image is: " + img_id + "."
        }
      }.merge(options).merge(Defaults.options)
      @options = options

    end
  end

  def options 
    @options
  end


end

