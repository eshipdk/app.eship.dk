
class GlsPricingMatrix < PricingScheme
  
  has_many :rows, :class_name => :GlsPricingRow, :dependent => :destroy
  accepts_nested_attributes_for :rows, :allow_destroy => true
  
  Interval = Struct.new(:from, :to) do
    def to_s
      'i' + from.to_s + '_' + to.to_s
    end
  end
  
  #Predefined weight intervals.
  #A weight is inside an interval if from <= weight < to
  def intervals
    [
      Interval.new(0, 1),
      Interval.new(1, 5),
      Interval.new(5, 10),
      Interval.new(10, 15),
      Interval.new(15, 20),
      Interval.new(20, 30)
    ]
  end
  
  def build
    #pass
  end
  
  def get_diesel_fee
    return (ConfigValue.get :gls_diesel_fee).to_f
  end
  
  def set_diesel_fee fee
    ConfigValue.set :gls_diesel_fee, fee.to_s
  end
  
  def handle_update params
    
    for i in 0.. rows.length - 1
      rows[i].mark_for_destruction
    end
    
    attrs = params.require(:pricing_scheme).permit().merge(
      {:rows_attributes => params.require(:pricing_scheme).require(:rows_attributes)})

    
    update attrs
    
    dfe = params.require(:pricing_scheme).permit(:enable_diesel_fee)
    set_extras_val(:enable_diesel_fee, dfe.key?(:enable_diesel_fee))
    save
    
  end
  
  
  
  def diesel_fee_enabled?
    val = get_extras_val :enable_diesel_fee
    val == nil ? false : val
  end
  
  
  def handle_cost_update params
    set_diesel_fee params.require(:pricing_scheme)[:diesel_fee]
    handle_update params
  end
  
  def handle_price_update params
    handle_update params
  end
  
  def add_fee value
    value * (1 + get_diesel_fee / 100)
  end
  
  def get_cost shipment
    get_price shipment #Assumes the cost is calculated using the cost scheme
  end
  
  def get_price shipment
    row = rows.where(:country_code => shipment.recipient.country_code).first
    if not row
      raise PriceConfigException.new 'No prices configured for country: ' + shipment.recipient.country_code 
    end
    weight = 0
    shipment.packages.each do |package|
      begin
        weight += package.weight * package.amount
      rescue NoMethodError #if a value is nil
        raise PriceConfigException.new 'Invalid weight/amount for shipment'
      end
    end
    
    intervals.each do |interval|
      if interval.from <= weight and weight < interval.to
        val = row.attributes[interval.to_s]
        if not val
          raise PriceConfigException.new 'No price configured for weight: ' + weight.to_s + '; country: ' + shipment.recipient.country_code
        end
        return val
      end
    end
    raise PriceConfigException.new 'Weight out of scope: ' + weight.to_s
  end
  
  def weight_class shipment
    weight = shipment.get_weight
    intervals.each do |interval|
      if interval.from <= weight and weight < interval.to
        return interval.from.to_s + ' - ' + interval.to.to_s
      end
    end
    return weight.to_s
  end
  
  def generate_invoice_rows shipments
    amount = 0
    rows = []
    shipments.each do |shipment|
      row = InvoiceRow.new
      price, issues = shipment.get_price
      if issues
        raise issues.to_s
      end
      amount += price
      row.amount = amount
      row.description = shipment.product.name + ': (' + shipment.recipient.country_code + ', ' + (weight_class shipment) + ')'
      rows.push(row)
    end
    if diesel_fee_enabled?
      row = InvoiceRow.new
      row.amount = amount * (get_diesel_fee * 0.01)
      row.description = shipments[0].product.name + ': Diesel fee'
      rows.push(row)
    end
    return rows
  end

  
end
