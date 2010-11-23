module Hadoop
  class Defaults
    @@options = {
      # default is Amazon's branded CentOS 5 variant.
      :base_image_label => "amzn-ami-0.9.9-beta.x86_64-ebs"
    }
    def Defaults.options
      @@options
    end
  end
  
end
