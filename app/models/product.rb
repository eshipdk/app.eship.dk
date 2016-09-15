class Product < ActiveRecord::Base
  
  
  def cost_scheme
    c = pricing_scheme_class
  
    cost_scheme = c.where(:pricing_type => PricingScheme.pricing_types[:cost]).first
    if cost_scheme == nil
      cost_scheme = c.new
      cost_scheme.pricing_type = :cost
      cost_scheme.save
    end
    return cost_scheme
  end
  
  def available_countries user
    price_scheme(user).available_countries
  end
  
  def price_scheme user
    c = pricing_scheme_class
    
    price_scheme = c.where(:pricing_type => PricingScheme.pricing_types[:price], :user => user).first
    if price_scheme == nil
      price_scheme = c.new
      price_scheme.pricing_type = :price
      price_scheme.user = user
      price_scheme.save
    end
    price_scheme.cost_scheme = cost_scheme
    return price_scheme
  end
  
  #Defines which class to model the pricing scheme based on the product code.
  def pricing_scheme_class 
    case product_code
    when 'glsb'
      return GlsbPricing
    when 'glsp'
      return GlspPricing
    when 'glsboc'
      return GlsbocPricing
    when 'glspoc'
      return GlspocPricing
    when 'glsproc'
      return GlsprocPricing
    when 'OC_glsproc'
      return OcGlsprocPricing
    else
      raise PriceConfigException.new("Pricing scheme does not exist for product: " + name)
    end
  end
  
  
end
