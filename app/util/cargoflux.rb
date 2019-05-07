# Utility for interaction with Cargoflux API
module Cargoflux
  API_ENDPOINT = 'https://api.cargoflux.com/api/v1/customers/shipments/'.freeze
  COMPANY_API_ENDPOINT = 'https://api.cargoflux.com/api/v1/companies/'.freeze
  COMPANY_API_TOKEN = '2fc352526bf0b161740773d3205e9c5a'.freeze

  def handle_submission_response(shipment, response)
    shipment.api_response = response.to_json.to_s
    if response['status'] != 'created'
      shipment.status = :failed
      shipment.label_pending = true
    else
      shipment.status = :response_pending
      shipment.request_id = response['request_id']
      shipment.cargoflux_shipment_id = response['unique_shipment_id']
    end
    shipment.save
  end

  def submit(shipment)
    return false unless shipment.can_submit

    response = do_submit(shipment)
    handle_submission_response(shipment, response)
    response
  end

  def perform_https_get(url, token)
    endpoint = URI.parse(url)
    https = Net::HTTP.new(endpoint.host, endpoint.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(endpoint.request_uri, 'access_token' => token)
    JSON.parse(https.request(request).body)
  end

  def fetch_company_data(shipment)
    return if shipment.cargoflux_shipment_id.nil?

    url = COMPANY_API_ENDPOINT + 'shipments/' + shipment.cargoflux_shipment_id
    response = perform_https_get(url, COMPANY_API_TOKEN)
    response['state'] = 'delivered' if
      response['state'] == 'delivered_at_destination'
    response
  end

  def fetch_state(shipment)
    return if shipment.cargoflux_shipment_id.nil?

    response = fetch_all shipment
    response['state']
  end

  def fetch_all(shipment)
    return if shipment.cargoflux_shipment_id.nil?

    endpoint = URI.parse(API_ENDPOINT + shipment.cargoflux_shipment_id)
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(endpoint.request_uri, initheader = { 'access_token' => shipment.user.cargoflux_api_key })

    response = JSON.parse http.request(request).body
    if response['state'] == 'delivered_at_destination'
      response['state'] = 'delivered'
    end
    response
  end

  def do_submit(shipment)
    endpoint = URI.parse API_ENDPOINT

    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true

    request = if shipment.must_retry?
                Net::HTTP::Put.new(endpoint.request_uri,
                                   initheader = { 'Content-Type' =>
                                     'application/json' })
              else
                Net::HTTP::Post.new(endpoint.request_uri,
                                    initheader = { 'Content-Type' =>
                                      'application/json' })
              end
    request.body = (request_payload shipment).to_json
    JSON.parse http.request(request).body
  end

  def request_payload(shipment)
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
        'callback_url' => EShip::HOST_ADDRESS + "/shipments/#{shipment.id}/callback",
        'return_label' => shipment.return,
        'shipment' => {
          'product_code' => product_code,
          'dutiable' => false,
          'description' => shipment.description,
          'reference' => shipment.reference,
          'remarks' => shipment.remarks,
          'shipping_date' => Time.now.strftime('%F'),
          'parcelshop_id' => shipment.parcelshop_id
        },
        'sender' => shipment.sender.attributes,
        'recipient' => shipment.recipient.attributes
      }
    data['sender']['address_line3'] = ''
    data['recipient']['address_line3'] = ''

    # If address line 2 is used and line 1 is empty we switch the values silently
    if (data['sender']['address_line1'] == '') && (data['sender']['address_line2'] != '')
      data['sender']['address_line1'] = data['sender']['address_line2']
      data['sender']['address_line2'] = ''
    end

    if (data['recipient']['address_line1'] == '') && (data['recipient']['address_line2'] != '')
      data['recipient']['address_line1'] = data['recipient']['address_line2']
      data['recipient']['address_line2'] = ''
    end

    if shipment.delivery_instructions && (shipment.delivery_instructions != '')
      data['shipment']['delivery_instructions'] = shipment.delivery_instructions
    end

    if shipment.dutiable
      data['shipment']['dutiable'] = true
      data['shipment']['customs_amount'] = shipment.customs_amount.to_s
      data['shipment']['customs_currency'] = shipment.customs_currency.upcase
      data['shipment']['customs_code'] = shipment.customs_code
    else
      data['shipment']['dutiable'] = false
    end

    package_dimensions = []
    shipment.packages.each do |package|
      dimensions = package.dimensions
      dimensions['weight'] = [dimensions['weight'].to_f, 0.1].max.to_s
      package_dimensions << dimensions
    end
    data['shipment']['package_dimensions'] = package_dimensions

    # Temporary fix to allow empty attention fields
    if data['sender']['attention'].nil? || (data['sender']['attention'].strip == '')
      data['sender']['attention'] = '-'
    end
    if data['recipient']['attention'].nil? || (data['recipient']['attention'].strip == '')
      data['recipient']['attention'] = '-'
    end

    if shipment.must_retry?
      data['unique_shipment_id'] = shipment.cargoflux_shipment_id
    end
    data
  end

  def update_shipments
    url = COMPANY_API_ENDPOINT + 'shipment_exports.xml' # ?since=2018-06-14+13%3A45%3A00+%2B0100'
    endpoint = URI.parse(url)
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(endpoint.request_uri,
                                  initheader = { 'access_token' =>
                                                COMPANY_API_TOKEN })

    r = Hash.from_xml http.request(request).body
    # r2 = r['ShipmentLists']['ShipmentList'][8]
    # r3 = r;
    # r = {}
    # r['OLD'] = r3;
    # r['ShipmentList'] = r2;
    # return r.to_json
    us = r['ShipmentList']['UpdatedShipments']
    ns = r['ShipmentList']['NewShipments']

    as = []
    as.concat(us['Shipment']) unless us['Shipment'].nil?
    as.concat(ns['Shipment']) unless ns['Shipment'].nil?

    if as.count == 0
      Rails.logger.info 'Pulled empty export feed!'
    else

      as.each do |hs|
        s = Shipment.where(cargoflux_shipment_id: hs['ShipmentId']).first
        if s.nil?
          Rails.logger.warn "Could not find shipment with id #{hs['ShipmentId']}."
          next
        end

        # Update state
        hs['State'] = 'delivered' if hs['State'] == 'delivered_at_destination'
        if hs['State'] != s.shipping_state
          Rails.logger.warn "Update shipping state of #{s.pretty_id} to #{hs['State']}"
          s.update_attribute(:shipping_state, hs['State'])
        end

        # Update prices
        s.update_prices hs
      end
    end

    r.to_json
  end

  def price_lookup(shipment)
    url = API_ENDPOINT + 'prices.json'
    endpoint = URI.parse(url)
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(endpoint.request_uri,
                                  initheader = { 'Content-Type' =>
                                                'application/json' })
    data = request_payload shipment
    data['package_dimensions'] = data['shipment']['package_dimensions']
    request.body = data.to_json
    data = JSON.parse http.request(request).body

    data.each do |prod|
      next unless prod['product_code'] == shipment.product.product_code

      price = prod['price_amount']
      return prod['price_amount'].to_f, false if price

      return nil, 'No price available'
    end
    [nil, 'Product not found']
  end
end
