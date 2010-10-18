#!/usr/bin/ruby

require 'test/unit'
$:.unshift File.join(File.dirname(__FILE__),"..", "lib")
require 'Himg.rb'

include Hadoop

class TestCreateImage < Test::Unit::TestCase
  def setup 
    @@foo = Himg.new
  end

  def test1 
    assert(@@foo)
    assert(@@foo.options)

    #required options:
    # for now, require a specific AMI: (Amazon-branded Ubuntu 10).
    assert(@@foo.options[:base_image_name] == "ami-04aa5f6d")
    assert(@@foo.options[:hbase_roles])
    assert(@@foo.options[:base_image_name])

    @@foo.options.keys.each do |key|
      puts "#{key} => #{@@foo.options[key]}\n"
    end

    assert(true)
  end

end

