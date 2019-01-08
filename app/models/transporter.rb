class Transporter < ActiveRecord::Base

  def self.options
    h = {'None'=>nil
        }
    Transporter.all.each do |t|
      h[t.name] = t.id
    end
    return h
  end
  
end
