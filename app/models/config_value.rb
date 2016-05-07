
#Basic key-value pair with unique keys used for admin managable configuration
class ConfigValue < ActiveRecord::Base
  
  def self.get key
    if cv = ConfigValue.where(:key => key).first
      return cv.value
    end
    return ""
  end
  
  def self.set key, value
    if cv = ConfigValue.where(:key => key).first
      cv.value = value
      cv.save
    else
      cv = ConfigValue.new
      cv.key = key
      cv.value = value
      cv.save
    end
  end
  
  
end