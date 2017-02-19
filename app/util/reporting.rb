
module Reporting
  
  def days_since_epoch ts
    (ts.to_i / 86400).floor
  end
  
  def wday ts
    ts.wday == 0 ? 6 : ts.wday - 1
  end
  
  
  def generate_booking_report from, to
    
    n_days = days_since_epoch(to) - days_since_epoch(from)
    
    if n_days < 30
      from = from
      granularity = :day
      group_by = 'DATE_FORMAT(DATE(created_at), "%Y-%m-%d")'      
    elsif n_days < 200
      from = from - (wday from) * 86400
      granularity = :week
      group_by = 'DATE_FORMAT(DATE(created_at) - WEEKDAY(created_at), "%Y-%m-%d")'
    else
      from = from  - (from.mday - 1) * 86400
      granularity = :month
      group_by = 'DATE_FORMAT(DATE(created_at) - DAYOFMONTH(created_at) + 1, "%Y-%m-%d")'
    end
    
    data = Shipment.group([group_by, 'shipping_state > 1'])
            .where('created_at >= DATE(?)', from)
            .where('created_at < DATE(?) + 1', to)
            .count

    res = {}
    date = from
    while date <= to
      
      date_s = date.strftime('%Y-%m-%d')
      
      initiated = data[[date_s, 0]].to_i
      shipped = data[[date_s, 1]].to_i
      
      res[date_s] = {        
        'total' => initiated + shipped,
        'shipped' => shipped,
        'idle' => initiated
      }
      
      if granularity == :day
        date = date + 1.days
      elsif granularity == :week
        date = date + 7.days
      else
        next_month = (date + 35.days)
        date = next_month - (next_month.mday - 1) * 86400
      end
    end
    return res
  end
  
end