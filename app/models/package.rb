class Package < ActiveRecord::Base
  belongs_to :shipment
  
  validates :width, numericality: { greater_than: 0 }
  validates :length, numericality: { greater_than: 0 }
  validates :height, numericality: { greater_than: 0 }
  validates :weight, numericality: { greater_than: 0 }
  validates :amount, numericality: { greater_than: 0 }
  
  
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
