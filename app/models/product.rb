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
  
  def default_price_scheme
    c = pricing_scheme_class
    
    default_scheme = c.where(:pricing_type => PricingScheme.pricing_types[:default_price]).first
    if default_scheme == nil
      default_scheme = c.new
      default_scheme.pricing_type = :default_price
      default_scheme.save
    end
    default_scheme.cost_scheme = cost_scheme
    return default_scheme
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
  
  def use_default_price_scheme user
    current_scheme = price_scheme user
    current_scheme.destroy
      
    default_scheme = default_price_scheme
    new_scheme = default_scheme.dup_deep
    new_scheme.user = user
    new_scheme.pricing_type = :price
    new_scheme.save
  end
  
  def available_countries user
    price_scheme(user).available_countries
  end

  def pricing_scheme_class_name
    "#{original_code.downcase.camelcase}Pricing"
  end

  # Returns the class representing this product's pricing scheme.
  # The class name is the camel casing of the product code.
  # If the class does not exist already, an anonymous class
  # is returned based on the IntervalTable pricing scheme.
  def pricing_scheme_class
    class_name = pricing_scheme_class_name
    begin
      return Object.const_get(class_name)
    rescue NameError
      klass = Class.new(IntervalTable)
      Object.const_set(class_name, klass)
      return Object.const_get(class_name)
    end
  end
  
  def code
    product_code
  end
  
end
