class Shipment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :product
  belongs_to :invoice
  belongs_to :sender, :class_name => 'Address', :foreign_key => 'sender_address_id', :dependent => :destroy
  belongs_to :recipient, :class_name => 'Address', :foreign_key => 'recipient_address_id', :dependent => :destroy

  #status label_ready has been deprecated. See label_pending bool
  enum status: [:initiated, :response_pending, :label_ready, :complete, :failed]


  

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
    return self.where('cargoflux_shipment_id LIKE :prefix', prefix: "#{pretty_id}%")
  }
  
  scope :filter_uninvoiced, ->(){
    return self.complete.where(invoiced: false)
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
    (JSON.parse api_response)
  end

  #Marks the shipment to have a pending label and registers when the label was pushed
  def register_label_pending
    self.label_pending = true
    self.label_pending_time = DateTime.now
  end
  
  def recent_label_pending?
    label_pending and label_pending_time > (DateTime.now - 1.hours)
  end

  



  def must_retry?
    return cargoflux_shipment_id != nil && cargoflux_shipment_id != ''
  end

 




  def api_response_error_msg
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
    when 'glsb', 'glsp'
      'https://gls-group.eu/DK/da/find-pakke?match=' + awb
    else
      'about:blank'
    end
  end
end
