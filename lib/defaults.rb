module Hadoop
  class Defaults
    @@options = {
      :base_image_name => "ami-04aa5f6d",
    }
    def Defaults.options
      @@options
    end
  end
  
end
