
class PricingScheme < ActiveRecord::Base
  
  
  belongs_to :user
  #A scheme instance of type cost is the internal price that we pay for a product
  #A scheme instance of type price is the price that the given customer is charged
  #Only schemes of type price should reference a user
  enum pricing_type: [:cost, :price, :default_price]
  
  attr_accessor :cost_scheme, :_product_code
  
  
  def cost_template
    raise self.to_s + "Cost template not implemented"
  end
  
  def price_template
    raise self.to_s + "Price template not implemented"
  end
  
  def default_price_template
    raise self.to_s + "Default price template not implemented"
  end
  
  def dup_deep
    raise self.to_s + "Deep duplication not implemented"
  end
  
  def build
    raise self.to_s + "Build not implemented"
  end
  
  def handle_cost_update params
    raise self.to_s + 'Cost update not implemented'  
  end
  
  def handle_price_update params
    raise self.to_s + 'Price update not implemented'
  end
  
  def get_price shipment, cache = true
    raise self.to_s + 'Price calculation not implemented'
  end
  
  def get_cost shipment, cache = true
    raise self.to_s + 'Cost calculation not implemented'
  end
  
  #Takes shipments to be invocied with
  #actual scheme and generates the rows to be
  #associated with the invoice
  def generate_invoice_rows shipments
    raise self.to_s + 'Invoice row generation not implemented'
  end
  
  def price_configured? shipment
    raise self.to_s + 'Shipment price configuration check not implemented'
  end
  
  def available_countries shipment
    raise self.to_s + 'Available countries not implemented'
  end
  
  #Returns an array of hashes containing information about available products and their prices within a specific country
  #E.g.: [{'title' => 'DK 1.0 kg - 2.0 kg', 'price' => 2.0}]
  def product_rows country
    raise self.to_s + 'Product rows not implemented'
  end
  
  def extras_data
    if self.extras == nil
      return {}
    end
    return JSON.parse self.extras
  end
  
  def set_extras_val key, val
    data = extras_data
    data[key.to_s] = val
    self.extras = data.to_json
  end
  
  def get_extras_val key
    data = self.extras_data
    data.key?(key.to_s) ? data[key.to_s] : nil
  end
  
  def get_diesel_fee_dk
    return PricingScheme.get_diesel_fee_dk
  end
  
  def get_diesel_fee_inter
    return PricingScheme.get_diesel_fee_inter
  end
  
  def self.get_diesel_fee_dk
    return (ConfigValue.get :diesel_fee_dk).to_f
  end
  
  def set_diesel_fee_dk fee
    ConfigValue.set :diesel_fee_dk, fee.to_s
  end

  def self.get_diesel_fee_inter
    return (ConfigValue.get :diesel_fee_inter).to_f
  end
  
  
  def set_diesel_fee_inter fee
    ConfigValue.set :diesel_fee_inter, fee.to_s
  end
  
  def diesel_fee_dk_enabled?
    val = get_extras_val :diesel_fee_dk
    val == nil ? false : val
  end
  
  def diesel_fee_inter_enabled?
    val = get_extras_val :diesel_fee_inter
    val == nil ? false : val
  end

  def cargoflux_prices_enabled?
    val = get_extras_val :cargoflux_prices
    val == nil ? false : val
  end

  # assumes to be called by a price scheme to get related cost scheme  
  def get_cost_scheme
    PricingScheme.where(:type => type, :pricing_type => PricingScheme.pricing_types[:cost]).first
  end

  # Attempts to update the customer prices to those set in cargoflux
  def use_cargoflux_prices
    raise self.to_s + 'Cargoflux pricing fetching not implemented'
  end

  def product_code
    return /^(.*)Pricing$/.match(self.class.name).captures[0].downcase
  end
  
end
