class Package < ActiveRecord::Base
  belongs_to :shipment
  
  
  def dimensions
    {
      'width' => width.to_s,
      'length' => length.to_s,
      'height' => height.to_s,
      'weight' => weight.to_s,
      'amount' => amount
    }  
  end
  
end
