
class IntervalTable < PricingScheme
  
  
  has_many :rows, :class_name => :IntervalRow, :dependent => :destroy 
  
  has_many :markup_rows, :class_name => :MarkupRow, :dependent => :destroy
  
    
  
  def build
    #pass
  end
  
  def get_attrs params
    return params.require(:pricing_scheme).permit().merge(
        {:rows_attributes => params.require(:pricing_scheme).require(:rows_attributes)})
  end
  
  def handle_update params
    
    begin
      mrow_attrs = params.require(:pricing_scheme).require(:markup_rows_attributes)
      mrow_attrs.each do |id, vals|
        mrow = MarkupRow.find id
        mrow.markup = vals[:markup]
        mrow.active = vals[:active]
        mrow.save
      end
    rescue ActionController::ParameterMissing
    end
    
    begin
      row_attrs = params.require(:pricing_scheme).require(:rows_attributes)            
      row_attrs.each do |i,vals|        
        if vals[:id]
          row = IntervalRow.find vals[:id]
          if vals[:remove]
            row.destroy
          else
            row.value = vals[:value]
            row.default_markup = vals[:default_markup]
            row.save
          end          
        else
          row = IntervalRow.new
          row.country_code = vals[:country_code]
          row.weight_from = vals[:weight_from]
          row.weight_to = vals[:weight_to]
          row.value = vals[:value]
          row.default_markup = vals[:default_markup] ? vals[:default_markup] : 0
          row.interval_table = self          
          row.save
        end
      end
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
    dfe = params.require(:pricing_scheme).permit(:diesel_fee_dk, :diesel_fee_inter, :cargoflux_prices)
    set_extras_val(:diesel_fee_dk, dfe.key?(:diesel_fee_dk))
    set_extras_val(:diesel_fee_inter, dfe.key?(:diesel_fee_inter))
    set_extras_val(:cargoflux_prices, dfe.key?(:cargoflux_prices))
    begin
      validate_available_intervals(get_attrs(params))
    rescue ActionController::ParameterMissing
    end
    handle_update params
  end
  
 
  
  def available_countries
    countries = Set.new
    for row in markup_rows
      if row.active
          countries.add(row.cost_break.country_code)
      end
      
    end
    return countries.to_a
  end
  
  def product_rows country
    res = []
    markup_rows.each do |row|
      if row.cost_break.country_code == country
        res.push({:title => "#{country} #{row.cost_break.weight_from} kg - #{row.cost_break.weight_to} kg", 
        :price => row.markup + row.cost_break.value})
      end
    end    
    return res
  end
  
  def price_configured? shipment
    shipment.packages.each do |package|      
      if not  markup_rows.joins(:cost_break).where(['active = 1 AND country_code LIKE ? AND weight_from <= ? AND weight_to > ?',
          shipment.recipient.country_code, package.weight, package.weight]).exists?
        return false
      end     
    end
    return true
  end
  
  def get_cost shipment, cache = true    
    return get_price(shipment, cache)
  end
  
  
  def get_price shipment, cache = true
      val = 0      
      title = "#{shipment.product.name}: #{shipment.recipient.country_code}"
      
      if self.pricing_type == 'cost'
        cost_scheme = self
      else
        cost_scheme = get_cost_scheme
      end
      
      shipment.packages.each do |package|
        begin
          cost_row = get_cost_row cost_scheme, shipment, package
          if self.pricing_type == 'cost'
            package.cost = cost_row.value * package.amount
            if cache
              package.save
            end
            val += package.cost
          else     
            markup_row = get_markup_row cost_row
            package.price = (markup_row.markup + cost_row.value) * package.amount
            package_class = "(#{cost_row.weight_from} - #{cost_row.weight_to} kg)"
            package.title = "#{title} #{package_class}"
            if cache
              package.save
            end
            val += package.price
          end
        rescue ActiveRecord::RecordNotFound
          issue = "WARNING: No price configured for country #{shipment.recipient.country_code}, weight #{package.weight} (shipment id #{shipment.pretty_id} user #{shipment.user.email})"
          Rails.logger.warn issue
          raise PriceConfigException.new issue
        end
      end
      return val 
  end
  
  def get_cost_row cost_scheme, shipment, package
    country_code = shipment.product.is_import ? shipment.sender.country_code : shipment.recipient.country_code
    return cost_scheme.rows.where(['country_code LIKE ? AND weight_from <= ? AND weight_to > ?',
      country_code, package.weight, package.weight]).first!
  end
  
  def get_markup_row cost_row
    return MarkupRow.where(:cost_break => cost_row, :interval_table => self, :active => true).first!    
  end
  
  def get_markup_rows
    cost_scheme = get_cost_scheme      
    mrows = []
    cost_scheme.rows.order(:country_code, :weight_from).each do |crow|
      mrow = MarkupRow.where(:interval_table => self, :cost_break => crow).first
      if mrow == nil
        mrow = MarkupRow.new
        mrow.interval_table = self
        mrow.cost_break = crow
        mrow.save
      end
      mrows.append mrow
    end
    return mrows
  end
  
  
  def generate_invoice_rows shipments

    fee_dk = 0
    fee_inter = 0
    hash = {}
    shipments.each do |shipment|
      package_total = 0  
      if shipment.has_package_prices
        # NEW INVOICE METHOD WITH INDIVIDUAL PRICES FOR PACKAGES  
        # ALSO ADDS A "MANUAL DISCOUNT" LINE TO HANDLE UPDATED
        # FINAL PRICE VALUES
        shipment.packages.each do |package|
          title = package.title
           if hash.key? title
              hash[title][:price] += package.price
              hash[title][:count] += package.amount
              hash[title][:cost] += package.cost
            else
              hash[title] = {:price => package.price, :count => package.amount,
                             :cost => package.cost}
            end
        end
        if shipment.final_price < shipment.price
          # Register manual discount
          title = 'Manual Discount'
          if hash.key? title
            hash[title][:price] += shipment.final_price - shipment.price
            hash[title][:count] += 1
            hash[title][:cost] += package.cost
          else
            hash[title] = {:price => shipment.final_price - shipment.price, :count => 1,
                            :cost => 0}
          end
        end
      else
        # OLD INVOICE METHOD
        title = "#{shipment.product.name}: #{shipment.recipient.country_code}"
        
        classes = {}
        shipment.packages.each do |package|
          begin
            row = rows.where(['country_code LIKE ? AND weight_from <= ? AND weight_to > ?', shipment.recipient.country_code, package.weight, package.weight]).first!
            package_class = "#{row.weight_from} - #{row.weight_to} kg"
          rescue ActiveRecord::RecordNotFound
            if shipment.final_price.blank? or shipment.cost.blank?
              issue = "WARNING: No price configured for country #{shipment.recipient.country_code}, weight #{package.weight} (shipment id #{shipment.pretty_id} user #{shipment.user.email})"
              Rails.logger.warn issue
              raise PriceConfigException.new issue
            else
              package_class = "#{package.weight} kg"
            end
          end
          if classes.key? package_class
            classes[package_class] += package.amount
          else
            classes[package_class] = package.amount
          end        
        end
        
        classes.sort.map do |k, v|
          title += " (#{k})"
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
      
      # -------------------------------------------------------------
      # FROM THIS LINE BELOW FUNCTIONALITY IS IDENTICAL FOR OLD VS NEW
      # -------------------------------------------------------------  
      if shipment.recipient.country_code == 'DK' and shipment.sender.country_code == 'DK'
         fee_dk += shipment.final_diesel_fee
      else
        fee_inter += shipment.final_diesel_fee
      end
    end
    
     
    rows = []
    hash.each do |title, value|
      row = InvoiceRow.new
      row.amount = value[:price]
      row.description = title
      row.product_code = shipments[0].economic_product_code
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



  def use_cargoflux_prices
    mrows = get_markup_rows
    mrows.each do |mrow|
      cbreak = mrow.cost_break

      p = Package.new
      p.length = 1
      p.width = 1
      p.height = 1
      p.weight = cbreak.weight_from + (cbreak.weight_to - cbreak.weight_from) / 2
      p.amount = 1

      pcode = self._product_code
      product = Product.find_by(product_code: pcode)

      s = Shipment.new
      s.product = product
      s.user = self.user        
      s.sender = Address.new
      s.sender.country_code = 'DK'
      s.recipient = Address.new
      s.recipient.country_code = cbreak.country_code
      s.packages = [p]

      price, issue = Cargoflux.price_lookup s
      # subtract diesel fee percentages
      p_fee = cbreak.country_code == 'DK' ? get_diesel_fee_dk : get_diesel_fee_inter
      if not issue
        mrow.markup = (price / (1 + p_fee * 0.01))  - cbreak.value
        mrow.save
      end
    end
  end
  
end
