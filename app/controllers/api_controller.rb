include CsvImporter
class ApiController < ApplicationController
  before_filter :authenticate_api, :except => :validate_key
  skip_before_filter :verify_authenticity_token




  def product_codes
    products = @current_user.products
    render :text => {'product_codes' => @current_user.products.map(&:product_code)}.to_json
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
    
    Cargoflux.submit shipment
    
    shipment.reload

    response = {'shipment_id' => shipment.pretty_id, 'status' => shipment.status}
    if shipment.status == 'failed'
      response['errors'] = shipment.api_response_error_msg
    end
    render :text => response.to_json
  end

  def shipment_info
    
    pretty_id = @api_params['shipment_id']
    shipment = Shipment.find_by_pretty_id pretty_id
    
    if shipment == nil || shipment.user != @current_user
      result = {'found' => false}
    else
      result = {
          'found' => true,
          'id'  => pretty_id,
          'status' => shipment.status
        }

      case shipment.status
      when 'failed'
        result['error'] = shipment.api_response_error_msg
      when 'complete'
        result['document_url'] = shipment.document_url
        result['tracking_url'] = shipment.tracking_url
      end
    end
    render :text => result.to_json
  end

  def fresh_labels

    ready_shipments = @current_user.shipments.where(label_pending: true).where(status: Shipment.statuses[:complete]).where(label_action: Shipment.label_actions[:print])

    recently_registered = []
    ready_shipments.each do |shipment|
      if shipment.recent_label_pending?
        recently_registered.push shipment
      end
      shipment.label_pending = false
      shipment.save
    end

    render :text => {'labels' => recently_registered.map(&:document_url), 
                      'awbs' => recently_registered.map(&:awb),
                      'ids' => recently_registered.map(&:cargoflux_shipment_id)}.to_json
  end

  def recent_failures

    error_shipments = @current_user.shipments.where(label_pending: true).where(status: Shipment.statuses[:failed])

    response = {}
    shipments = []
    error_shipments.each do |shipment|

      shipment.label_pending = false
      errorShipment = {'id' => shipment.id, 'shipping_id' => shipment.cargoflux_shipment_id, 'errors' => shipment.get_error}
      shipments.push errorShipment

     shipment.save
    end

    render :text => {'shipments'=>shipments}.to_json

  end
  
  def validate_key
    
    
    render :text => {'valid' => (authenticate_api true)}.to_json
    
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
      render :text => e
      return
    end
    if res['error']
      api_error res['msg']
      return
    end
    api_success
  end

end
