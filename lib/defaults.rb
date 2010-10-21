module Hadoop
  class Defaults
    @@options = {
      :base_image_name => "ami-38c33651"
    }
    def Defaults.options
      @@options
    end
  end
  
end
