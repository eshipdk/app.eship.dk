include Cargoflux
class Shipment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :product
  belongs_to :invoice
  belongs_to :sender, :class_name => 'Address', :foreign_key => 'sender_address_id', :dependent => :destroy
  belongs_to :recipient, :class_name => 'Address', :foreign_key => 'recipient_address_id', :dependent => :destroy
  has_many :packages, :dependent => :destroy
  accepts_nested_attributes_for :packages, :allow_destroy => true
  
  #status label_ready has been deprecated. See label_pending bool
  #This status describes the state of the shipment booking itself
  enum status: [:initiated, :response_pending, :label_ready, :complete, :failed]
  
  #The shiping state represents the state pulled from CF for a shipment that has been booked
  enum shipping_state: [:na, :booked, :in_transit, :delivered, :cancelled]
  
  enum label_action: [:print, :email]
  
  def pretty_id(id = self.id)
    #return "%09d" % id
    if cargoflux_shipment_id
      return cargoflux_shipment_id
    end
    return 'e' + id.to_s
  end
  
  scope :filter_pretty_id, ->(pretty_id){
    if(pretty_id == '' || pretty_id == nil) 
      return self.all
    end
    if pretty_id[0,1] == 'e'
      id = pretty_id[1..-1].to_i
      return self.where(id: id)
    end
    return self.where('cargoflux_shipment_id LIKE ?', "#{pretty_id}%")
  }
  
  scope :filter_uninvoiced, ->(){
    self.complete.where(['invoiced = ? AND (shipping_state IN (2, 3))', false])
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
    if status != 'complete' or ['delivered', 'cancelled'].include? shipping_state
      return
    end
    update_attribute(:shipping_state, (Cargoflux.fetch_state self))
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
    (JSON.parse api_response)
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
    case product.product_code
    when 'daod'
      'http://www.tracktrace.dk/index.php?stregkode=' + awb
    when 'glsb', 'glsp', 'glsboc', 'glspoc', 'glsproc'
      'https://gls-group.eu/DK/da/find-pakke?match=' + awb
    else
      'about:blank'
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
  
  def calculate_price
    issue = false
    case user.billing_type
    when 'free'
      price = 0
    when 'flat_price'
      price = user.unit_price
    when 'advanced'
      begin
        scheme = product.price_scheme user
        price = (scheme.get_price self).round(2)
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
  
  def calculate_diesel_fee
    price, _ = get_price
    scheme = product.price_scheme(user)
    if recipient.country_code == 'DK'
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
  
  def price_configured?
    product.price_scheme(user).price_configured? self
  end
  
  def determine_value
    get_cost
    price, _ = calculate_price

    if price != nil
      self.final_price = price
      self.diesel_fee = calculate_diesel_fee
      self.final_diesel_fee = diesel_fee
      self.value_determined = true
      save
    end
  end
  
  def self.update_pending_shipping_states
    Rails.logger.info "#{Time.now.utc.iso8601} RUNNING TASK: Shipment.update_pending_shipping_states"
    pending_shipments = Shipment.where('shipping_state in (1, 2)')
    
    Rails.logger.info "Number of shipments to update: #{pending_shipments.length}"
    for shipment in pending_shipments
      shipment.update_shipping_state
    end
    
    Rails.logger.info "#{Time.now.utc.iso8601} TASK ENDED: Shipment.update_pending_shipping_states"
  end
  
end
