# require 'hcluster'

module Hadoop

class Faulkner < HCluster
  def initialize(options = {} )
    options = {
      :setup_kerberized_hbase => true
    }.merge(options)
    super(options)
  end

  def test()
    ssh("mkdir -p faulkner/lib")
    scp("#{ENV['HOME']}/hbase-ec2/faulkner/faulkner.rb","faulkner")
    scp("#{ENV['HOME']}/hbase-ec2/faulkner/lib/distributions.rb","faulkner/lib")
    scp("#{ENV['HOME']}/hbase-ec2/faulkner/lib/uuid.rb","faulkner/lib")
    ssh("hbase shell /root/faulkner/faulkner.rb")
  end
end

end