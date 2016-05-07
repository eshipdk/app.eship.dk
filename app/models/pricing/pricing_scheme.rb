
class PricingScheme < ActiveRecord::Base
  
  belongs_to :user
  #A scheme instance of type cost is the internal price that we pay for a product
  #A scheme instance of type price is the price that the given customer is charged
  #Only schemes of type price should reference a user
  enum pricing_type: [:cost, :price]
  
  
  def cost_template
    raise "Cost template not implemented"
  end
  
  def price_template
    raise "Price template not implemented"
  end
  
  def build
    raise "Build not implemented"
  end
  
  def handle_cost_update params
    raise 'Cost update not implemented'  
  end
  
  def handle_price_update params
    raise 'Price update not implemented'
  end
  
  def get_price shipment
    raise 'Price calculation not implemented'
  end
  
  def get_cost shipment
    raise 'Cost calculation not implemented'
  end
  
  
end