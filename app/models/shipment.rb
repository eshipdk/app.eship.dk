include Cargoflux
include Taxing
class Shipment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :product
  belongs_to :invoice
  has_many :additional_charges
  belongs_to :sender, :class_name => 'Address', :foreign_key => 'sender_address_id', :dependent => :destroy
  belongs_to :recipient, :class_name => 'Address', :foreign_key => 'recipient_address_id', :dependent => :destroy
  has_many :packages, :dependent => :destroy
  accepts_nested_attributes_for :packages, :allow_destroy => true
  
  #status label_ready has been deprecated. See label_pending bool
  #This status describes the state of the shipment booking itself
  enum status: [:initiated, :response_pending, :label_ready, :complete, :failed]
  
  #The shiping state represents the state pulled from CF for a shipment that has been booked
  enum shipping_state: [:na, :booked, :in_transit, :delivered, :cancelled, :problem]
  
  enum label_action: [:print, :email]
  
  def pretty_id(id = self.id)
    #return "%09d" % id
    if cargoflux_shipment_id
      return cargoflux_shipment_id
    end
    return 'e' + id.to_s
  end
  
  def n_packages
    packages.map {|p| p.amount}.sum
  end
  
  scope :filter_pretty_id, ->(pretty_id){
    if(pretty_id == '' || pretty_id == nil) 
      return self.all
    end
    if pretty_id[0,1] == 'e'
      id = pretty_id[1..-1].to_i
      return self.where(id: id)
    end
    return self.where('cargoflux_shipment_id LIKE ?', "%#{pretty_id}%")
  }
  

  scope :filter_uninvoiced, ->(user){
    #Label customers pay for all bookings. Shipping customers only pay for
    #shipments after they have been delivered so that extra charges may be included.
    if user.customer_type == 'shipping'
      return self.complete.where(['invoiced = false AND (shipping_state IN (2, 3, 5))', false])
    else
      if user.invoice_failed_bookings
        return self.where(['invoiced = ?', false])
      else
        return self.complete.where(['invoiced = ?', false])  
      end
    end
    #self.complete.where(invoiced: false)
  }
  
  scope :filter_recipient_name, ->(recipient_name){
    return self.joins(:recipient).where('company_name LIKE ?', "%#{recipient_name}%")
  }
  
  def self.find_by_pretty_id pretty_id
    if(pretty_id == '' || pretty_id == nil) 
      return nil
    end
    if pretty_id[0,1] == 'e'
      id = pretty_id[1..-1].to_i
      return self.find(id)
    end
    return find_by_cargoflux_shipment_id(pretty_id)
  end
  
  def update_shipping_state
    self.update_shipping_state_and_prices
  end

  def update_shipping_state_and_prices
    if status != 'complete' or ['delivered', 'cancelled'].include? shipping_state
      return
    end
    # If the customer is a shipping customer, update the shipment
    # prices from cargoflux
    if self.user.customer_type == 'shipping'
      cfdata = Cargoflux.fetch_company_data self
      update_attribute(:shipping_state, cfdata['state'])
      update_prices cfdata
    else
      update_attribute(:shipping_state, (Cargoflux.fetch_state self))
    end
  end

  def update_prices cfdata = false
    if self.user.customer_type != 'shipping'
      return
    end
    if not cfdata
      cfdata = Cargoflux.fetch_company_data self
    end
    if cfdata.key? 'price_lines'
      cfdata['price_lines'].each do |row|
        if row['line_description'] == 'Shipment charge'
          if self.cost < row['line_cost_price'].to_f
            oldcost = self.cost
            self.cost = row['line_cost_price']
            self.final_price = self.final_price + self.cost - oldcost
          end
        elsif row['line_description'] == 'Fuel charge'
          if self.final_diesel_fee < row['line_sales_price'].to_f
            self.final_diesel_fee = row['line_sales_price']
          end
        end
      end
      save
    end
  end
  
  def update_booking_state     
    data = Cargoflux.fetch_all self    
    if data == nil
      return
    end
    cf_state = data['state']
    if cf_state == 'created'
      return    
    elsif cf_state == 'booking_failed'
      update_attribute(:status, :failed)
    else
      update_attribute(:status, :complete)
      shipping_state = cf_state
      awb = data['awb']
      document_url = data['awb_link']
      determine_value
      save
    end    
  end

  def address(type)
    if new_record?
      return Address.new
    else
      if type == 'sender'
        return sender
      else
        if type == 'recipient'
          return recipient
        end
      end
    end
    return nil
  end

  def can_edit
    status == 'initiated' || status == 'failed'
  end

  def can_submit
    status == 'initiated' || status == 'failed'
  end

  def can_print
    status == 'complete' || status == 'label_ready'
  end

  def can_reprint
    (status == 'complete' || status == 'failed') && !label_pending
  end

  def can_delete
    (status == 'initiated' || status == 'failed')
  end
  
  def label_pending?
    label_pending
  end

  def get_error
    if not price_configured?
      return {'errors' => [{'description' => 'Pricing could not be determined for this shipment!'}]}
    end
    if api_response != nil
      return (JSON.parse api_response)
    end   
  end

  #Marks the shipment to have a pending label and registers when the label was pushed
  def register_label_pending
    self.label_pending = true
    self.label_pending_time = DateTime.now
  end
  
  def recent_label_pending?
    label_pending and label_pending_time != nil and label_pending_time > (DateTime.now - 1.hours)
  end

  
  def self.label_action_options
    {(self.label_action_title :print) => :print, (self.label_action_title :email) => :email}
  end
  
  def self.booking_state_options required = true
    opts = Shipment.statuses.map { |key, value| [key.humanize, key] } 
    if not required
      opts.unshift(['', ''])
    end
    return opts  
  end
  
  def self.shipping_state_options required = true
    opts = Shipment.shipping_states.map { |key, value| [key.humanize, key] } 
    if not required
      opts.unshift(['', ''])
    end
    return opts  
  end
  
  
  def self.label_action_title code
    case code.to_s
    when 'print'
        'Print'
    when 'email'
        'Email'
    end
  end
  
  def label_action_title
    Shipment.label_action_title label_action
  end

  def must_retry?
    return cargoflux_shipment_id != nil && cargoflux_shipment_id != ''
  end


  def api_response_error_msg
    if not price_configured?
      return 'Pricing could not be determined for this shipment!'
    end
    if !api_response
      return "No response"
    end
    begin
      hash = JSON.parse api_response
      if hash['status'] == 'failed'
        return hash['errors'][0]['description']
      end
    rescue
      return api_response
    end
  end

    
  def tracking_url
    if product.tracking_url_prefix.blank?
      "about:blank"
    else
      product.tracking_url_prefix + awb
    end
  end
  
  def calculate_cost
    issue = false
    case user.billing_type
    when 'advanced'
      begin
        scheme = product.cost_scheme
        cost = (scheme.get_cost self).round(2)
      rescue PriceConfigException => e
        issue = e.issue
      end
    else
      return 0, issue
    end
    return cost, issue
  end
  
  def get_cost
    
    if not self.cost
      calculated, issue = calculate_cost
      if issue
        return nil, issue
      else
        self.cost = calculated
        save
        return calculated, nil
      end
    end
    return self.cost, nil
  end
  
  def calculate_price cache = true
    issue = false
    case user.billing_type
    when 'free'
      price = 0
    when 'flat_price'
      price = user.unit_price * get_label_qty
    when 'advanced'
      begin
        scheme = product.price_scheme user
        price = (scheme.get_price(self, cache)).round(2)
      rescue PriceConfigException => e
        issue = e.issue
      end
    end
    return price, issue
  end
  
  def get_price
    if not self.price
      calculated, issue = calculate_price
      if issue
        return nil, issue
      else        
        self.price = calculated
        save
        return calculated, nil
      end
    end
    return self.price, nil
  end
  
  def calculate_diesel_fee cache = true
    if user.billing_type != 'advanced'
      return 0
    end
    if cache
      price, _ = get_price
    else
      price, _ = calculate_price false
    end
    scheme = product.price_scheme(user)
    if recipient.country_code == 'DK' and sender.country_code == 'DK'
      if scheme.diesel_fee_dk_enabled?
        return price * scheme.get_diesel_fee_dk * 0.01
      end
    else
      if scheme.diesel_fee_inter_enabled?
        return price * scheme.get_diesel_fee_inter * 0.01
      end
    end
    return 0
  end
  
  def get_weight
    weight = 0
    packages.each do |package|
      begin
        weight += package.weight * package.amount
      rescue NoMethodError
      end
    end
    return weight
  end

  def get_label_qty
    qty = 0
    packages.each do |package|
      qty += package.amount
    end
    return qty
  end
  
  def price_configured?
    begin
      user.billing_type == 'advanced' ? product.price_scheme(user).price_configured?(self) : true
    rescue PriceConfigException
      false
    end
  end
  
  def determine_value
    get_cost
    price, _ = calculate_price
    
    if user.billing_type == 'flat_price' and user.monthly_free_labels_remaining > 0
      freebies = [get_label_qty, user.monthly_free_labels_remaining].min
      price -= freebies * user.unit_price
      user.monthly_free_labels_expended += freebies
      user.save
    end

    if price != nil
      self.price = price
      self.final_price = price
      self.diesel_fee = calculate_diesel_fee
      self.final_diesel_fee = diesel_fee
      self.value_determined = true
      save
    end
  end
  
  def has_package_prices
    return packages[0].price != nil
  end
    
    
  def fetch_packages_from_cargoflux
    # Updates the package configuration by pulling it from cargoflux
    data = Cargoflux.fetch_all self
    dims = data['package_dimensions']
    self.packages.each do |p|
      p.destroy
    end
    dims.each do |d|
      p = Package.new
      p.length = d['length']
      p.width = d['width']
      p.height = d['height']
      p.weight = d['weight'].to_i           
      p.amount = d['amount'].to_i
      p.shipment = self
      p.save
    end        
  end


  # Returns the code of the product use in the shipment with respects to economic
  def economic_product_code
    code = product.product_code
    if not Taxing.european_union_countries.include?(sender.country_code)
      code += '_taxfree'
    end
    return code
  end
  
  def self.update_pending_shipping_states
    Rails.logger.warn "#{Time.now.utc.iso8601} RUNNING TASK: Shipment.update_pending_shipping_states"
    
    from_time = DateTime.now() - 360.days
    pending_shipments = Shipment.where(['shipping_state in (1, 2, 5) AND created_at > ?', from_time])
    
    Rails.logger.warn "Number of shipments to update: #{pending_shipments.length}"
    for shipment in pending_shipments
        begin
          shipment.update_shipping_state
        rescue => e
          Rails.logger.warn "#{Time.now.utc.iso8601} EXCEPTION UPDATING SHIPMENT #{shipment.id}: #{e.to_s}"
          issue = "#{e.to_s}: #{e.backtrace.join("\n")}"
          Rails.logger.warn issue
          SystemMailer.shipment_status_update_failed(shipment, issue).deliver_now
        end
    end
    
    Rails.logger.warn "#{Time.now.utc.iso8601} TASK ENDED: Shipment.update_pending_shipping_states"
  end
  
  def self.update_pending_booking_states
    Rails.logger.warn "#{Time.now.utc.iso8601} RUNNING TASK: Shipment.update_pending_booking_states"
    Shipment.where(:status => 1).each do |shipment|
      shipment.update_booking_state
    end
    Rails.logger.warn "#{Time.now.utc.iso8601} TASK ENDED: Shipment.update_pending_booking_states"
  end
  
end
