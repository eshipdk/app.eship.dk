using PatternMatch
module Reporting
  
  def days_since_epoch ts
    (ts.to_i / 86400).floor
  end
  
  def wday ts
    ts.wday == 0 ? 6 : ts.wday - 1
  end

  def get_granularity from, to
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

    return [from, granularity, group_by]
  end



  def generate_report from, to, model, select,  extra_group, extra_where, f_reader

    match(get_granularity(from, to)) do
      with(_[from2, granularity, group_by]) do
        from = from2

        if extra_group
          groups = [group_by, extra_group]
          group_index = "CONCAT(#{group_by}, ':', #{extra_group})"
        else
          groups = group_by
          group_index = group_by
        end

        rows = model.group(groups)
                 .where('created_at >= DATE(?)', from)
                 .where('created_at < DATE(?) + 1', to)
        if extra_where
          rows = rows.where(extra_where)
        end
        rows = rows.select("(#{group_index}) as g")
                 .select(select).to_a

        data = {}
        rows.each do |row|
          data[row.g] = row
        end

        res = {}
        date = from
        while date <= to

          date_s = date.strftime('%Y-%m-%d')
          res[date_s] = f_reader.call(data, date_s)

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

  end

  def generate_booking_report from, to
    fread = lambda {|data, date_s| puts
      ki = "#{date_s}:0"
      initiated = data.key?(ki) ? data[ki].count : 0
      ks = "#{date_s}:1"
      shipped = data.key?(ks) ? data[ks].count : 0
      return {'idle' => initiated,
              'shipped' => shipped,
              'total' => initiated + shipped}
    }
    select = 'count(*) as count'
    return generate_report from, to, Shipment, select,
                           'shipping_state > 1', false, fread
  end


  def generate_invoice_report from, to
    fread = lambda {|data, date_s| puts
      if data.key? date_s
        r = data[date_s]
        return {'netto' => r.netto, 'cost' => r.cost,
                'profit' => r.profit,
                'house_commission' => r.house_commission,
                'affiliate_commission' => r.affiliate_commission}
      else
        return {'netto' => 0, 'cost' => 0, 'profit' => 0,
                'house_commission' => 0, 'affiliate_commission' => 0}
      end
    }
    select = 'sum(amount) as netto, sum(gross_amount) as gross, ' +
             'sum(cost) as cost, sum(profit) as profit, ' +
             'sum(house_commission) as house_commission, ' +
             'sum(affiliate_commission) as affiliate_commission'
    return generate_report from, to, Invoice, select, false,
                           'economic_id IS NOT NULL', fread
  end


end

