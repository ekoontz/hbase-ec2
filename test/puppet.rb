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
    # for now, require a specific AMI: (Amazon-branded Ubuntu 10).
    assert(@@global_himg.options[:base_image_name] == "ami-38c33651")
    assert(@@global_himg.options[:hbase_roles])
    assert(@@global_himg.options[:base_image_name])

    @@global_himg.options.keys.each do |key|
      puts "#{key} => #{@@global_himg.options[key]}\n"
    end

    launch = HCluster::do_launch({
                                   :ami => @@global_himg.options[:base_image_name],
                                   :key_name => "root",
                                   :instance_type => "m1.large",
                                   :on_boot => lambda{|instance|
                                     image_creator_hostname = instance.dnsName
                                     puts "#{image_creator_hostname}: verifying that sshing works.."
                                     HCluster::until_ssh_able([instance],0,"ec2-user")
                                     puts "..ok."
                                   }
                                 },"image-creator")

    if (launch && launch[0])
      @image_creator = launch[0]
    else
      raise "Could not launch image creator."
    end

    assert(true)
  end

end

