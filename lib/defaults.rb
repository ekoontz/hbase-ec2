module Hadoop
  class Defaults
    @@options = {
      :base_image_name => "ami-38c33651",
      :java_url => "http://ekoontz-tarballs.s3.amazonaws.com/jdk-6u22-linux-x64.bin"
    }
    def Defaults.options
      @@options
    end
  end
  
end
