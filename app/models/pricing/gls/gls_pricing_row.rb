
class GlsPricingRow < ActiveRecord::Base
  
  belongs_to :gls_pricing_matrix
   
  def s_country_code
    return country_code == nil ? '' : country_code
  end
end
