
class GlsprocPricing < IntervalTable
  
  def cost_template
    return "pricing/interval/cost"
  end
  
  def price_template
    return "pricing/interval/price"
  end
  
end