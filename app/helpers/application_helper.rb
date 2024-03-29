# Date and time printing
module TimePrint
  def print_datetime(datetime)
    if datetime.nil?
      '-'
    else
      datetime.in_time_zone('Berlin').strftime('%H:%M:%S %d-%m-%Y')
    end
  end

  def print_date(datetime)
    if datetime.nil?
      '-'
    else
      datetime.in_time_zone('Berlin').strftime('%d-%m-%Y')
    end
  end
end

# Bootstrap custom fields
module BootstrapFields
  def bstxt_field(object_name, method, options = {})
    text_field(object_name, method, append_form_control(options))
  end

  def bspwd_field(object_name, method, options = {})
    password_field(object_name, method, append_form_control(options))
  end

  def bscountry_select(method, priority_countries = nil,
                       options = {}, html_options = {})
    country_select(method, priority_countries,
                   options.merge(include_blank: 'Select country...'),
                   append_form_control(html_options))
  end

  def bscurrency_select(method, selected = nil, options = {})
    bssel(method, options_for_select(Currency.get_options, selected), options)
  end

  def bssel(name, option_tags = nil, options = {})
    select_tag(name, option_tags, options.merge(class: 'form-control'))
  end

  def bschckbx(name, value = 1, checked = false, options = {})
    check_box_tag(name, value, checked,
                  append_form_control(options).merge(style: 'width: 34px;'))
  end
end

# Context box module
module CBox
  def cbox_grid_paging(models, show_filter = false)
    render partial: 'layouts/cbox_grid_paging',
           locals: { models: models, filter: show_filter }
  end

  # Content box helpers..
  def cbox(&block)
    html = "<div class='content-box'>"
    html << capture(&block).to_s
    html << '</div>'
    raw html
  end

  def cbox_header(title, &links_block)
    html = "<div class='content-box-header'>"\
           "<span class='title'>#{title}</span><span class='pull-right'>"
    html << capture(&links_block).to_s
    html << '</span></div>'
    raw html
  end

  def cbox_subheader(title, &links_block)
    html = "<div class='content-box-subheader'>"\
           "<span class='title'>#{title}</span><span class='pull-right'>"
    html << capture(&links_block).to_s
    html << '</span></div>'
    raw html
  end
end

# Key-value box module
module KeyValueBox
  def kv_pair(key, value, title = true)
    if title
      raw "<span class='key'>#{key}</span>"\
          "<span class='value' title='#{value}'>#{value}</span>"
    else
      raw "<span class='key'>#{key}</span><span class='value'>#{value}</span>"
    end
  end

  def kv_box(map, titles = true)
    html = '<div class="key-value-box">'
    map.keys.each do |key|
      html << kv_pair(key, map[key], titles)
    end
    html << '</div>'
    raw html
  end

  def block_kv_pair(key, &valueblock)
    html = '<div class=block-key-value-box>'\
           "<div class='key'>#{key}</div><div class='value'>"
    html << capture(&valueblock).to_s
    html << '</div></div>'
    raw html
  end
end

# General purpose helper
module ApplicationHelper
  include Currency
  include TimePrint
  include BootstrapFields
  include CBox
  include KeyValueBox
  # General bootstrap form builder
  class ActionView::Helpers::FormBuilder
    def bstxt_field(method, options = {})
      text_field(method, append_form_control(options))
    end

    def bsnum_field(method, options = {})
      number_field(method, options.merge(class: 'form-control'))
    end

    def bssel(method, sel_options = {}, options = {}, html_options = {})
      select(method, sel_options, options,
             html_options.merge(class: 'form-control'))
    end

    def bschckbx(method, options = {})
      check_box(method, options.merge(class: 'form-control'))
    end
  end

  def append_form_control(options)
    options.merge(
      class:
        if options.key?(:class)
          options[:class] + ' form-control'
        else
          'form-control'
        end
    )
  end

  def currency(value, currency = ' kr.', round_to = 2)
    if value
      rep = number_with_precision(value, precision: round_to).tr('.', ',')
      "<span class='currency-value'>#{rep}#{currency}</span>".html_safe
    else
      ''
    end
  end

  def percent(value, round_to = 2)
    rep = number_with_precision(value, precision: round_to).tr('.', ',')
    "<span class='percent'>#{rep}%</span>".html_safe
  end

  def display_pagination(collection)
    total = collection.total_entries
    from =  [1 + (collection.current_page - 1) * collection.per_page, total].min
    to = [from + collection.per_page - 1, total].min
    "<span class='pagination-counter'>Showing"\
    " #{from} to #{to} of #{total}</span>".html_safe
  end

  def country_name(country_code)
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end

  def grid_before(models)
    render partial: 'layouts/grid_before', locals: { models: models }
  end

  def grid_after(models)
    render partial: 'layouts/grid_after', locals: { models: models }
  end

  def date_filter
    render partial: 'layouts/date_filter'
  end

  def glyphicon(name)
    "<span class='glyphicon glyphicon-#{name}'></span>".html_safe
  end

  def btn_link(url, title, type = 'default')
    html = "<a href='#{url}' class='btn btn-#{type}'>#{title}</a>"
    raw html
  end

  def tbl(clickable, &block)
    html = "<table class='table table-hover"\
           "#{clickable ? 'table-hover-pointer' : ''} table-condensed'>"
    html << capture(&block).to_s
    html << '</table>'
    raw html
  end

  def cell_safe(str, max_width)
    html = "<td title='#{str}'>"\
           "<div class='safe-cell' style='max-width:"\
           "#{max_width}px'>#{str}</div></td>"
    raw html
  end

  def row_link(url, &block)
    html = "<tr onclick='window.location=\"#{url}\"' class='link'>"
    html << capture(&block).to_s
    html << '</tr>'
    raw html
  end

  def bool_sign(bool)
    if bool
      glyphicon 'ok-sign'
    else
      glyphicon 'minus-sign'
    end
  end

  def bool_select(key, default = true, selected = nil)
    opts = if default
             { '' => '', 'Yes' => 1, 'No' => 0 }
           else
             { 'Yes' => 1, 'No' => 0 }
           end
    bssel key, options_for_select(opts, selected)
  end
end
