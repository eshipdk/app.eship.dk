
module Cargoflux
  
  API_ENDPOINT = 'https://api.cargoflux.com/api/v1/customers/shipments/'
  
  
  def submit shipment
    if !shipment.can_submit
      return false
    end

    response = do_submit shipment

    shipment.api_response = response.to_json.to_s

    if response['status'] == 'failed'
      shipment.status = :failed
      shipment.label_pending = true
    else
      shipment.status = :response_pending
      shipment.request_id = response['request_id']
      shipment.cargoflux_shipment_id = response['unique_shipment_id']
    end
    shipment.save
    return response
  end
  
  def fetch_state shipment
    if shipment.cargoflux_shipment_id == nil
      return
    end
    response = fetch_all shipment
    return response['state']
  end
    
  def fetch_all shipment
    if shipment.cargoflux_shipment_id == nil
      return
    end
    endpoint = URI.parse(API_ENDPOINT + shipment.cargoflux_shipment_id)
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(endpoint.request_uri, initheader = {'access_token' => shipment.user.cargoflux_api_key})
      
    response = JSON.parse http.request(request).body
    if response['state'] == 'delivered_at_destination'
      response['state'] = 'delivered'
    end
    return response
  end

  def do_submit shipment
    endpoint = URI.parse API_ENDPOINT

    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true

    if shipment.must_retry?
      request = Net::HTTP::Put.new(endpoint.request_uri,
                                   initheader = {'Content-Type' =>
                                     'application/json'})
    else
      request = Net::HTTP::Post.new(endpoint.request_uri,
                                  initheader = {'Content-Type' =>
                                    'application/json'})
    end                        
    request.body = (request_payload shipment).to_json
    return JSON.parse http.request(request).body
  end
  
  
  def request_payload shipment
    product_code = shipment.product.product_code
    if shipment.recipient.country_code != 'DK'
        if product_code == 'glsb'
          product_code = 'glsboc'
        elsif product_code == 'glsp'
          product_code = 'glsp'
        end
    end
    
    data =
    {
      'access_token' => shipment.user.cargoflux_api_key,
      'callback_url' => EShip::HOST_ADDRESS + "shipments/#{shipment.id}/callback",
      'return_label' => shipment.return,
      'shipment' => {
        'product_code' => product_code,
        'dutiable' => false,
        'description' => shipment.description,
        'reference' => shipment.reference,
        'remarks' => shipment.remarks,
        'shipping_date' => Time.now.strftime("%F"),
        'parcelshop_id' => shipment.parcelshop_id
      },
      'sender' => shipment.sender.attributes,
      'recipient' => shipment.recipient.attributes
    }
    data['sender']['address_line3'] = ''
    data['recipient']['address_line3'] = ''
    
    #If address line 2 is used and line 1 is empty we switch the values silently
    if data['sender']['address_line1'] == '' and data['sender']['address_line2'] != ''
      data['sender']['address_line1'] = data['sender']['address_line2']
      data['sender']['address_line2'] = ''
    end
    
    if data['recipient']['address_line1'] == '' and data['recipient']['address_line2'] != ''
      data['recipient']['address_line1'] = data['recipient']['address_line2']
      data['recipient']['address_line2'] = ''
    end
 
    if shipment.delivery_instructions and shipment.delivery_instructions != ''
      data['shipment']['delivery_instructions'] = shipment.delivery_instructions
    end
    
    package_dimensions = []
    shipment.packages.each do |package|
      dimensions = package.dimensions
      dimensions['weight'] = ([dimensions['weight'].to_f, 0.1].max).to_s
      package_dimensions << dimensions
    end
    data['shipment']['package_dimensions'] = package_dimensions
    
    #Temporary fix to allow empty attention fields
    if data['sender']['attention'] == nil or data['sender']['attention'].strip == ''
      data['sender']['attention'] = '-'
    end
    if data['recipient']['attention'] == nil or data['recipient']['attention'].strip == ''
      data['recipient']['attention'] = '-'
    end
    
    if shipment.must_retry?
      data['unique_shipment_id'] = shipment.cargoflux_shipment_id
    end
    return data
  end
  
end