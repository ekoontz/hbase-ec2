load File.dirname(__FILE__)+'/../lib/TestDFSIO.rb'
include Hadoop

options = {
  :label => 'hbase-0.20-tm-3-x86_64',
  :num_regionservers => 3
}
cluster = TestDFSIO.new options
cluster.launch
cluster.test
cluster.terminate
