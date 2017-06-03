
class MarkupRow  < ActiveRecord::Base
  
  belongs_to :interval_table 
  belongs_to :cost_break, :class_name => 'IntervalRow' , :foreign_key => 'cost_break_id', :primary_key => 'id'
  
  
end