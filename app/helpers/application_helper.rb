module ApplicationHelper
  
class ActionView::Helpers::FormBuilder
  def bstxt_field(method, options = {})
    text_field(method, options.merge(class: 'form-control'))
  end
  
  def bsnum_field(method, options = {})
    number_field(method, options.merge(class: 'form-control'))
  end
  
  def bssel(method, sel_options = {}, promt = {}, options = {})
    select(method, sel_options, promt, options.merge(class: 'form-control'))
  end
  
  

  
end

  def bstxt_field(object_name, method, options = {})
    text_field(object_name, method, options.merge(class: 'form-control'))
  end
  
  def bscountry_select(method, priority_countries = nil, options = {}, html_options = {})
      country_select(method, priority_countries, options.merge(:include_blank => 'Select country...'), html_options.merge(class: 'form-control'))
  end
end
