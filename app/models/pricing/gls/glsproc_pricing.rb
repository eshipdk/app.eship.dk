
class GlsprocPricing < GlsPricingMatrix
  
  def cost_template
    return "pricing/gls/cost"
  end
  
  def price_template
    return "pricing/gls/price"
  end
  
end