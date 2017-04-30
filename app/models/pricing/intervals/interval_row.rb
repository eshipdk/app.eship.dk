
class IntervalRow  < ActiveRecord::Base
  
  belongs_to :interval_table
  has_many :markup_row, :foreign_key => 'cost_break_id', :dependent => :destroy
  
  validates :country_code, :presence => true
  validates :weight_from, :presence => true
  validates :weight_to, :presence => true
  validates :value, :presence => true
  validates :default_markup, :presence => true
  

  def s_country_code
    return country_code == nil ? '' : country_code
  end
  
  def sort_value
    ApplicationController.helpers.country_name(country_code) + weight_from.to_s.rjust(10, '0')
  end
  
end