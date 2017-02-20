module ApplicationHelper
  
class ActionView::Helpers::FormBuilder
  def bstxt_field(method, options = {})
    text_field(method, options.merge(class: 'form-control'))
  end
  
  def bsnum_field(method, options = {})
    number_field(method, options.merge(class: 'form-control'))
  end
  
  def bssel(method, sel_options = {}, options = {}, html_options = {})
    select(method, sel_options, options, html_options.merge(class: 'form-control'))
  end
  
  def bschckbx(method, options = {})
    check_box(method, options.merge(class: 'form-control'))
  end

  
end

  def bstxt_field(object_name, method, options = {})
    text_field(object_name, method, options.merge(class: 'form-control'))
  end
  
  def bscountry_select(method, priority_countries = nil, options = {}, html_options = {})
      country_select(method, priority_countries, options.merge(:include_blank => 'Select country...'), html_options.merge(class: 'form-control'))
  end
  
  def bssel(name, option_tags = nil, options = {})
    select_tag(name, option_tags, options.merge(class: 'form-control'))
  end
  
  def bschckbx(name, value = 1, checked = false, options={})
    check_box_tag(name, value, checked, options.merge(class: 'form-control', style: 'width: 34px;'))
  end
  
  def print_datetime datetime
    datetime == nil ? '-' : datetime.in_time_zone('Berlin').strftime('%H:%M:%S %d-%m-%Y')
  end
  
  def print_date datetime
    datetime == nil ? '-' : datetime.in_time_zone('Berlin').strftime('%d-%m-%Y')
  end
  
  def currency value, currency = ' kr.', round_to = 2
    "<span class='currency-value'>#{number_with_precision(value, :precision => round_to).gsub('.', ',')}#{currency}</span>".html_safe
  end
  
  def percent value, round_to = 2
    "<span class='percent'>#{number_with_precision(value, :precision => round_to).gsub('.', ',')}%</span>".html_safe
  end
  
  def display_pagination collection
    total = collection.total_entries
    from =  [1 + (collection.current_page - 1) * collection.per_page, total].min
    to = [from + collection.per_page - 1, total].min
    "<span class='pagination-counter'>Showing #{from} to #{to} of #{total}</span>".html_safe
  end

  def country_name country_code
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end
  
  def grid_before models
    render :partial => 'layouts/grid_before', :locals => {:models => models}
  end

  def grid_after models
    render :partial => 'layouts/grid_after', :locals => {:models => models}
  end
  
  def date_filter
    render :partial => 'layouts/date_filter'
  end
end
