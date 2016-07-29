
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
  
  def diesel_fee_dk_enabled?
    val = get_extras_val :diesel_fee_dk
    val == nil ? false : val
  end
  
  def diesel_fee_inter_enabled?
    val = get_extras_val :diesel_fee_inter
    val == nil ? false : val
  end
  
  def available_countries
    countries = Set.new
    for row in rows
      countries.add row.country_code
    end
    return countries.to_a
  end
  
  def price_configured? shipment
    rows.exists?(['country_code LIKE ? AND weight_from <= ? AND weight_to > ?', shipment.recipient.country_code, shipment.get_weight, shipment.get_weight])
  end
  
  def get_cost shipment
    return get_price shipment
  end
  
  def get_price shipment
    begin
      row = rows.where(['country_code LIKE ? AND weight_from <= ? AND weight_to > ?', shipment.recipient.country_code, shipment.get_weight, shipment.get_weight]).first!
      return row.value
    rescue ActiveRecord::RecordNotFound
      raise PriceConfigException.new "No price configured for country #{shipment.recipient.country_code}, weight #{shipment.get_weight}"
    end
  end
  
  
  def generate_invoice_rows shipments
    
  
    amount_dk = 0
    amount_inter = 0
    hash = {}
    shipments.each do |shipment|
      price_class = rows.where(['country_code LIKE ? AND weight_from <= ? AND weight_to > ?', shipment.recipient.country_code, shipment.get_weight, shipment.get_weight]).first!
      title = "#{shipment.product.name}: (#{price_class.country_code}: #{price_class.weight_from} - #{price_class.weight_to})"
      
      price, issues = shipment.get_price #Price must be fetched through the shipment in case it has a custom price
      if issues
        raise issues.to_s
      end
      
      if hash.key? title
        hash[title][:price] += price
        hash[title][:count] += 1
      else
        hash[title] = {:price => price, :count => 1}
      end
      
      if shipment.recipient.country_code == 'DK'
        amount_dk += price
      else
        amount_inter += price
      end
      
    end

    rows = []
    hash.each do |title, value|
      row = InvoiceRow.new
      row.amount = value[:price]
      row.description = "#{title} X #{value[:count]}"
      rows.push(row)
    end
    
    if diesel_fee_dk_enabled?
      row = InvoiceRow.new
      row.amount = amount_dk * (get_diesel_fee_dk * 0.01)
      row.description = shipments[0].product.name + ': Diesel fee (DK)'
      rows.push(row)
    end
    
    if diesel_fee_inter_enabled?
      row = InvoiceRow.new
      row.amount = amount_inter * (get_diesel_fee_inter * 0.01)
      row.description = shipments[0].product.name + ': Diesel fee (International)'
      rows.push(row)
    end

    return rows
  end
  
end