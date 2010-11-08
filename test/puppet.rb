#!/usr/bin/ruby

require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__),"..", "lib")
require 'Himg.rb'
require 'hcluster.rb'

include Hadoop

class TestCreateImage < Test::Unit::TestCase
  def setup 
    @@global_himg = Himg.new
  end

  def test1 
    assert(@@global_himg)
    assert(@@global_himg.options)

    #required options:
    # for now, require a specific AMI: (Amazon-branded CentOS 5 variant).
    assert(@@global_himg.options[:base_image_name] == "ami-38c33651")
    assert(@@global_himg.options[:hbase_roles])
    assert(@@global_himg.options[:base_image_name])

#    @@global_himg.options.keys.each do |key|
#      puts "#{key} => #{@@global_himg.options[key]}\n"
#    end

    cluster = HCluster.new :label => 'amzn-ami-0.9.9-beta.x86_64-ebs'
    cluster.launchp(:slaves => 0)

    assert(cluster.dnsName)

    #wait for hbase to come up, and run some hadoop and hbase tests.
    puts "master hostname " + cluster.dnsName
    cluster.slaves.each {|slave|
      puts " slave: " + slave.dnsName
    }

  end
end

