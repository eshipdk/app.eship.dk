
module Cargoflux
  
  
  
  def submit shipment
    if !shipment.can_submit
      return false
    end

    response = do_submit shipment

    shipment.api_response = response.to_json.to_s

    if response['status'] != 'waiting_for_booking' && response['status'] != 'booking_initiated'
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
  
  
  def api_endpoint
    URI.parse('https://www.cargoflux.com/api/v1/customers/shipments')
    #URI.parse('http://requestb.in/1i1oxsi1')
  end

  def do_submit shipment
    endpoint = api_endpoint

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
    data =
    {
      'access_token' => shipment.user.cargoflux_api_key,
      'callback_url' => EShip::HOST_ADDRESS + "shipments/#{shipment.id}/callback",
      'return_label' => shipment.return,
      'shipment' => {
        'product_code' => shipment.product.product_code,
        'dutiable' => false,
        "package_dimensions" =>
        [
         {
           "amount" => shipment.amount,
           "height" => shipment.package_height.to_s,
           "length" => shipment.package_length.to_s,
           "weight" => shipment.package_weight.to_s,
           "width" => shipment.package_width.to_s
         }
        ],
        'description' => shipment.description,
        'reference' => shipment.reference,
        'shipping_date' => Time.now.strftime("%F"),
        'parcelshop_id' => shipment.parcelshop_id
      },
      'sender' => shipment.sender.attributes,
      'recipient' => shipment.recipient.attributes
    }
    data['sender']['address_line3'] = ''
    data['recipient']['address_line3'] = ''
    
    #Temporary fix to allow empty attention fields
    if data['sender']['attention'].strip == ''
      data['sender']['attention'] = '-'
    end
    if data['recipient']['attention'].strip == ''
      data['recipient']['attention'] = '-'
    end
    
    if shipment.must_retry?
      data['unique_shipment_id'] = shipment.cargoflux_shipment_id
    end
    return data
  end
  
  
end