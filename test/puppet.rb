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

    @@global_himg.options.keys.each do |key|
      puts "#{key} => #{@@global_himg.options[key]}\n"
    end

    launch = HCluster::do_launch({
                                   :ami => @@global_himg.options[:base_image_name],
                                   :key_name => "root",
                                   :security_group => "all open",
                                   :instance_type => "m1.large",
                                   :on_boot => lambda{|instance|
                                     master_hostname = instance.dnsName
                                     puts "#{master_hostname}: verifying that sshing works.."
                                     HCluster::until_ssh_able([instance],0,"ec2-user")
                                     puts "..ok."
                                     HCluster::scp_to(master_hostname,"./lib/puppet/master.sh","/home/ec2-user/master.sh","ec2-user")
                                     HCluster::ssh_to(master_hostname,"sh /home/ec2-user/master.sh",
                                                      HCluster.echo_stdout,
                                                      HCluster.echo_stderr,
                                                      nil,nil,
                                                      "ec2-user")
                                     
                                     #check to make sure puppetmaster (and puppet) are running on master host.

                                   }
                                 },"master")


    if (launch && launch[0])
      @master = launch[0]
    else
      raise "Could not launch master."
    end

    assert(@master)
    
    #set up slaves.
    puppetmaster_private_ip = @master.privateIpAddress
    
    @slaves = []

    2.times { |i|
      launch = HCluster::do_launch({
                                     :ami => @@global_himg.options[:base_image_name],
                                     :key_name => "root",
                                     :instance_type => "m1.large",
                                     :security_group => "all open",
                                     :on_boot => lambda{|instance|
                                       slave_hostname = instance.dnsName
                                       puts "#{slave_hostname}: verifying that sshing to slave works.."
                                       HCluster::until_ssh_able([instance],0,"ec2-user")
                                       puts "..ok."
                                       
                                       puts "copying slave script.."
                                       HCluster::scp_to(instance.dnsName,"./lib/puppet/slave.sh","/home/ec2-user/slave.sh","ec2-user")
                                       puts "..ok."
                                       
                                       puts "run slave setup.."
                                       #run slave setup.
                                       HCluster::ssh_to(slave_hostname,
                                                        "sudo sh ./slave.sh '"+puppetmaster_private_ip+"'",
                                                        HCluster.echo_stdout,
                                                        HCluster.echo_stderr,
                                                        nil,
                                                        nil,
                                                        "ec2-user")
                                       puts "..ok."
                                     }
                                   },"start_slave_"+i.to_s)
      assert(launch[0])     
      @slaves.push launch[0]
    }

    #wait for hbase to come up, and run some hadoop and hbase tests.
    puts "master hostname " + @master.dnsName + " ; private IP: " + puppetmaster_private_ip
    @slaves.each {|slave|
      puts " slave: " + slave.dnsName
    }

  end
end

