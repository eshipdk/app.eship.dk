include CsvImporter
class ApiController < ApplicationController
  before_filter :authenticate_api, :except => [:validate_key, :client_version]
  skip_before_filter :verify_authenticity_token




  def product_codes
    products = @current_user.products
    ps = products.select(:product_code, :name).map { |p| {:product_code => p.product_code, :name => p.name}}
    render :text => {'products' => ps}.to_json, :content_type => 'application/json'
  end


  def create_shipment

    shipment_params = @api_params['shipment']
    
    begin
      product = @current_user.find_product shipment_params['product_code']
    rescue => ex
      api_error 'Invalid product code: ' + shipment_params['product_code']
      return false
    end

    sender = Address.new(shipment_params['sender'])
    
    recipient = Address.new(shipment_params['recipient'])
    
    if !sender.valid?
      api_error 'Invalid sender information: ' + sender.to_json
      return
    end
    
    if !recipient.valid?
      api_error 'Invalid recipient information: ' + recipient.to_json
      return
    end
    
    sender.save
    recipient.save
    
    
    shipment = Shipment.new
    shipment.user = @current_user
    shipment.product = product
    shipment.sender = sender
    shipment.recipient = recipient
    
    shipment.return = shipment_params['return']
    shipment.reference = shipment_params['reference']
    shipment.description = shipment_params['description']
    shipment.delivery_instructions = shipment_params['delivery_instructions']
    shipment.parcelshop_id = shipment_params['parcelshop_id']
    shipment.callback_url = shipment_params['callback_url']
   
    shipment.save
    
    package = Package.new
    package.height = shipment_params['package_height']
    package.length = shipment_params['package_length']
    package.width = shipment_params['package_width']
    package.weight = shipment_params['package_weight']
    package.amount = shipment_params['amount']
    package.shipment = shipment
    package.save
    
    
    if shipment.price_configured?
      Cargoflux.submit shipment
    else
      shipment.status = 'failed'
      shipment.save
    end
    
    shipment.reload

    response = {'shipment_id' => shipment.pretty_id, 'status' => shipment.status}
    if shipment.status == 'failed'
      response['errors'] = shipment.api_response_error_msg
    end
    render :text => response.to_json, :content_type => 'application/json'
  end

  def shipment_info
    
    shipment = @current_user.shipments
    query = ''
    if @api_params.key? 'shipment_id' and @api_params.key? 'reference'
      shipment = shipment.filter_pretty_id(@api_params['shipment_id']).where(['reference LIKE ?', @api_params['reference']]).last
    elsif @api_params.key? 'shipment_id'
      shipment = shipment.find_by_pretty_id(@api_params['shipment_id'])
    elsif @api_params.key? 'reference'
      shipment = shipment.where(['reference LIKE ?', @api_params['reference']]).last
    else
      shipment = nil
    end

    if shipment == nil
      result = {'found' => false}
    else
      result = {
          'found' => true,
          'id'  => shipment.pretty_id,
          'status' => shipment.status
        }

      case shipment.status
      when 'failed'
        result['error'] = shipment.api_response_error_msg
      when 'complete'
        result['document_url'] = shipment.document_url
        result['tracking_url'] = shipment.tracking_url
        result['shipping_state'] = shipment.shipping_state
      end
    end
    render :text => result.to_json,  :content_type => 'application/json'
  end

  def fresh_labels

    ready_shipments = @current_user.shipments.where(label_pending: true)
      .where(status: Shipment.statuses[:complete])
      .where(label_action: Shipment.label_actions[:print])
      .limit(5)


    recently_registered = []
    ready_shipments.each do |shipment|
      # To ensure that the same shipment is not printed by two concurrent
      # clients it is locked pessimistically for the procedure determining
      # whether to print it.
      # The same procedure also flags it as printed so the queued client
      # will not print it as well.
      shipment.with_lock do
        if shipment.recent_label_pending?
          recently_registered.push shipment
        end
        shipment.label_pending = false
        shipment.save!
      end
    end

    render :text => {'labels' => recently_registered.map(&:document_url),
                      'awbs' => recently_registered.map(&:awb),
                      'ids' => recently_registered.map(&:cargoflux_shipment_id),
                      'references' => recently_registered.map(&:reference),
                      'returns' => recently_registered.map(&:return)}.to_json,  :content_type => 'application/json'
  end

  def recent_failures

    error_shipments = @current_user.shipments.where(label_pending: true).where(status: Shipment.statuses[:failed])

    response = {}
    shipments = []
    error_shipments.each do |shipment|
      shipment.with_lock do
        if shipment.label_pending
          shipment.label_pending = false
          errorShipment = {'id' => shipment.id, 'shipping_id' => shipment.cargoflux_shipment_id, 'errors' => shipment.get_error}
          shipments.push errorShipment
        end
        shipment.save!
      end
    end

    render :text => {'shipments'=>shipments}.to_json,  :content_type => 'application/json'

  end
  
  def validate_key
    
    render :text => {'valid' => (authenticate_api true)}.to_json,  :content_type => 'application/json'
    
  end
  
  def client_version
    begin
      files = Dir["#{Rails.root}/public/client/*.*"]
      version = files.sort[0][/[^\/]*\z/]
    rescue => ex
      version = '0.0'
    end
    render :text => {'version' => version}.to_json,  :content_type => 'application/json'
  end


  def upload_csv
    csv = @api_params['csv']
    if !csv
      api_error "Missing attribute: csv"
      return
    end
    begin
      res = CsvImporter.import_csv csv, @current_user
    rescue Exception => e
      api_error e.to_s
      return
    end
    if res['error']
      api_error res['msg']
      return
    end
    api_success
  end
  
  
# POSTNORD API 
  
  def pn_servicepoint_by_address
    url = 'https://api2.postnord.com/rest/businesslocation/v1/servicepoint/findNearestByAddress.json?apikey=e882a3b4126a72f01d95be8411d43938'
    @api_params.each do |k,v|
      if k != 'api_key'
        url += "&#{k}=#{v}"
      end
    end
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)
    render :text => http.request(request).body,  :content_type => 'application/json'
  end

end
