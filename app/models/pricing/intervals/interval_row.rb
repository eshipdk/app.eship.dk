
class IntervalRow  < ActiveRecord::Base
  
  belongs_to :interval_table
  
  validates :country_code, :presence => true
  validates :weight_from, :presence => true
  validates :weight_to, :presence => true
  validates :value, :presence => true
  
  def s_country_code
    return country_code == nil ? '' : country_code
  end
  
end