
class IntervalTable < PricingScheme
  
  
  has_many :rows, :class_name => :IntervalRow, :dependent => :destroy
  accepts_nested_attributes_for :rows, :allow_destroy => true
  
    
  
  def build
    #pass
  end
  
  def get_attrs params
    return params.require(:pricing_scheme).permit().merge(
        {:rows_attributes => params.require(:pricing_scheme).require(:rows_attributes)})
  end
  
  def handle_update params
    
    for i in 0.. rows.length - 1
      rows[i].mark_for_destruction
    end

    begin
      attrs = get_attrs params
      validate_overlapping_intervals attrs
      update attrs
    rescue ActionController::ParameterMissing 
    end
    
    save
  end
  
  def validate_overlapping_intervals attrs
    rows_attrs = attrs[:rows_attributes].values
    for i in 0 .. rows_attrs.length - 2 #Do not compare last element to itself
      i_attrs = rows_attrs[i]
      i_attrs[:weight_to] = i_attrs[:weight_to].to_f
      i_attrs[:weight_from] = i_attrs[:weight_from].to_f
      for j in i + 1 .. rows_attrs.length - 1
        j_attrs = rows_attrs[j]
        j_attrs[:weight_to] = j_attrs[:weight_to].to_f
        j_attrs[:weight_from] = j_attrs[:weight_from].to_f
        if i_attrs[:country_code] == j_attrs[:country_code] and i_attrs[:weight_to] > j_attrs[:weight_from] and j_attrs[:weight_to] > i_attrs[:weight_from]
          raise PriceConfigException.new 'UPDATE DROPPED: Overlapping intervals detected!'
        end
      end
    end
  end
  
  def validate_available_intervals attrs
    rows_attrs = attrs[:rows_attributes].values
    for row in rows_attrs
      accepted = false
      for cost_row in cost_scheme.rows
        if row[:country_code] == cost_row.country_code and row[:weight_from].to_f >= cost_row.weight_from and row[:weight_to].to_f <= cost_row.weight_to
          accepted = true
          break
        end
      end
      if not accepted
        raise PriceConfigException.new "UPDATED DROPPED: Interval not available: #{row[:country_code]} #{row[:weight_from]} -> #{row[:weight_to]}"
      end
    end
  end
  
  def handle_cost_update params
    set_diesel_fee_dk params.require(:pricing_scheme)[:diesel_fee_dk]
    set_diesel_fee_inter params.require(:pricing_scheme)[:diesel_fee_inter]
    handle_update params
  end
  
  
  def handle_price_update params
    dfe = params.require(:pricing_scheme).permit(:diesel_fee_dk, :diesel_fee_inter)
    set_extras_val(:diesel_fee_dk, dfe.key?(:diesel_fee_dk))
    set_extras_val(:diesel_fee_inter, dfe.key?(:diesel_fee_inter))
    begin
      validate_available_intervals (get_attrs params)
    rescue ActionController::ParameterMissing
    end
    handle_update params
  end
  
 
  
  def available_countries
    countries = Set.new
    for row in rows
      countries.add row.country_code
    end
    return countries.to_a
  end
  
  def product_rows country
    res = []
    rows.where('country_code LIKE ?', country).each do |row|
      res.push({:title => "#{country} #{row.weight_from} kg - #{row.weight_to} kg", :price => row.value})
    end
    return res
  end
  
  def price_configured? shipment
    shipment.packages.each do |package|
      if not rows.exists?(['country_code LIKE ? and weight_from <= ? and weight_to > ?', shipment.recipient.country_code, package.weight, package.weight])
        return false
      end
    end
    return true
  end
  
  def get_cost shipment
    return get_price shipment
  end
  
  def get_price shipment
    
      val = 0
      shipment.packages.each do |package|
        begin
          row = rows.where(['country_code LIKE ? AND weight_from <= ? AND weight_to > ?', shipment.recipient.country_code, package.weight, package.weight]).first!
          val += row.value * package.amount
        rescue ActiveRecord::RecordNotFound
          issue = "WARNING: No price configured for country #{shipment.recipient.country_code}, weight #{package.weight} (shipment id #{shipment.pretty_id} user #{shipment.user.email})"
          Rails.logger.warn issue
          raise PriceConfigException.new issue
        end
      end
      return val
  end
  
  
  def generate_invoice_rows shipments

    fee_dk = 0
    fee_inter = 0
    hash = {}
    shipments.each do |shipment|
      
      title = "#{shipment.product.name}: #{shipment.recipient.country_code}"
      
      classes = {}
      shipment.packages.each do |package|
        begin
          row = rows.where(['country_code LIKE ? AND weight_from <= ? AND weight_to > ?', shipment.recipient.country_code, package.weight, package.weight]).first!
          package_class = "#{row.weight_from} - #{row.weight_to} kg"
          if classes.key? package_class
            classes[package_class] += package.amount
          else
            classes[package_class] = package.amount
          end
        rescue ActiveRecord::RecordNotFound
          issue = "WARNING: No price configured for country #{shipment.recipient.country_code}, weight #{package.weight} (shipment id #{shipment.pretty_id} user #{shipment.user.email})"
          Rails.logger.warn issue
          raise PriceConfigException.new issue
        end
      end
      
      classes.sort.map do |k, v|
        title += " (#{k})"
      end
      
      if shipment.recipient.country_code == 'DK'
       fee_dk += shipment.final_diesel_fee
      else
        fee_inter += shipment.final_diesel_fee
      end
      
      if hash.key? title
        hash[title][:price] += shipment.final_price
        hash[title][:count] += 1
        hash[title][:cost] += shipment.cost
      else
        hash[title] = {:price => shipment.final_price, :count => 1,
                       :cost => shipment.cost}
      end
    end
    rows = []
    hash.each do |title, value|
      row = InvoiceRow.new
      row.amount = value[:price]
      row.description = title
      row.product_code = shipments[0].product.product_code
      row.qty = value[:count]
      row.unit_price = (row.amount / row.qty).round(2)
      row.cost = value[:cost]
      rows.push(row)
    end
    
    if fee_dk > 0
      row = InvoiceRow.new
      row.amount = fee_dk
      row.description = shipments[0].product.name + ': Diesel fee (DK)'
      row.product_code = 'diesel_fee'
      row.qty = 1
      row.unit_price = row.amount
      row.cost = fee_dk
      rows.push(row)
    end
    
    if fee_inter > 0
      row = InvoiceRow.new
      row.amount = fee_inter
      row.description = shipments[0].product.name + ': Diesel fee (International)'
      row.product_code = 'diesel_fee'
      row.qty = 1
      row.unit_price = row.amount
      row.cost = row.amount
      rows.push(row)
    end

    return rows
  end
  
  def cost_template
    return "pricing/interval/cost"
  end
  
  def price_template
    return "pricing/interval/price"
  end
  
  def default_price_template
    return "pricing/interval/default_price"
  end
  
  def dup_deep
    res = dup
    res.save
    rows.each do |row|
      row_dup = row.dup
      row_dup.interval_table = res
      row_dup.save
    end
    return res
  end
  
end
