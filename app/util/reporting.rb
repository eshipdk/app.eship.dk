
module Reporting
  
  def generate_booking_report from, to
    
  
    data = Shipment.group(['DATE_FORMAT(DATE(created_at), "%Y-%m-%d")', 'shipping_state > 1'])
            .where('created_at >= DATE(?)', from)
            .where('created_at <= DATE(?)', to)
            .count
            
    res = {}
    date = from
    while date <= to
      date = date + 1.days
      date_s = date.strftime('%Y-%m-%d')
      
      initiated = data[[date_s, 0]].to_i
      shipped = data[[date_s, 1]].to_i
      
      res[date_s] = {        
        'total' => initiated + shipped,
        'shipped' => shipped,
        'idle' => initiated
      }
    end

    return res
  end
  
end