require 'csv'
class Shipment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :product

  belongs_to :sender, :class_name => 'Address', :foreign_key => 'sender_address_id'
  belongs_to :recipient, :class_name => 'Address', :foreign_key => 'recipient_address_id'

  #status label_ready has been deprecated. See label_pending bool
  enum status: [:initiated, :response_pending, :label_ready, :complete, :failed]


  

  def pretty_id(id = self.id)
    #return "%09d" % id
    if cargoflux_shipment_id
      return cargoflux_shipment_id
    end
    return 'e' + id.to_s
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

  def submit
    if !can_submit
      return false
    end

    response = do_submit

    self.api_response = response.to_json.to_s

    if response['status'] != 'waiting_for_booking' && response['status'] != 'booking_initiated'
      self.status = :failed
      self.label_pending = true
    else
      self.status = :response_pending
      self.request_id = response['request_id']
      self.cargoflux_shipment_id = response['unique_shipment_id']
    end
    self.save
    return response
  end


  def cargoflux_api_uri
    URI.parse('https://www.cargoflux.com/api/v1/customers/shipments')
    #URI.parse('http://requestb.in/1i1oxsi1')
  end


  def must_retry?
    return cargoflux_shipment_id != nil && cargoflux_shipment_id != ''
  end

  def request_data
    data =
    {
      'access_token' => user.cargoflux_api_key,
      'callback_url' => EShip::HOST_ADDRESS + "shipments/#{id}/callback",
      'return_label' => self.return,
      'shipment' => {
        'product_code' => product.product_code,
        'dutiable' => false,
        "package_dimensions" =>
        [
         {
           "amount" => "1",
           "height" => package_height.to_s,
           "length" => package_length.to_s,
           "weight" => (package_weight).to_s,
           "width" => package_width.to_s
         }
        ],
        'description' => self.description,
        'reference' => pretty_id,
        'shipping_date' => Time.now.strftime("%F"),
      },
      'sender' => sender.attributes,
      'recipient' => recipient.attributes
    }
    data['sender']['address_line3'] = ''
    data['recipient']['address_line3'] = ''
    if must_retry?
      data['unique_shipment_id'] = cargoflux_shipment_id
    end
    return data
  end


  def self.import_csv content, user
    #values = CSV.parse (content.gsub ';', ',') Both comma and semicolon. Issue: Weight described with comma
    values = CSV.parse content, {:col_sep => ';'}
    validation = validate_csv_values values, user
    if !validation['error']
      values.each do |row|
        hash = csv_row_hash user, row
        shipment = Shipment.new
        shipment.product = Product.find_by_product_code hash['product_code']
        shipment.user = user
        shipment.package_weight = hash['package_weight'].gsub ',', '.'
        shipment.package_length = hash['package_length']
        shipment.package_width = hash['package_width']
        shipment.package_height = hash['package_height']
        shipment.description = hash['description']

        sender = Address.new hash['sender']
        shipment.sender = sender

        recipient = Address.new hash['recipient']
        shipment.recipient = recipient

        shipment.save
        shipment = Shipment.find shipment.id

        shipment.submit
      end
    end
    return validation
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

private

  def self.validate_csv_values values, user
    if !user.import_format.complete?
      return import_error "Import format is incomplete.", 0
    end
    values.each_with_index do |row, index|
      line_number = index + 1

      if row.length < user.import_format.min_cols
        return import_error "No. of columns (#{row.length}) does not match import format (#{user.import_format.min_cols})", line_number
      end

      hash = csv_row_hash user, row
      product_code = hash['product_code']
      if !user.products.map(&:product_code).include? product_code
        return import_error "Invalid product code '#{product_code}'", line_number
      end
    end
    return {'error'=>false}
  end

  def self.csv_row_hash user, row
    {
      'return'=>( row_val user, row, 'return'),
      'product_code' =>( row_val user, row, 'product_code'),
      'package_height'=>( row_val user, row, 'package_height'),
      'package_length'=>(  row_val user, row, 'package_length'),
      'package_width'=>( row_val user, row, 'package_width'),
      'package_weight'=>( row_val user, row, 'package_weight'),
      'description' => ( row_val user, row, 'description' ),
      'sender'=>{
        'company_name'=>(  row_val user, row, 'sender_company_name'),
        'attention'=>( row_val user, row, 'sender_attention'),
        'address_line1'=>( row_val user, row, 'sender_address_line1'),
        'address_line2'=>( row_val user, row, 'sender_address_line2'),
        'zip_code'=>( row_val user, row, 'sender_zip_code'),
        'city'=>( row_val user, row, 'sender_city'),
        'country_code'=>( row_val user, row, 'sender_country_code'),
        'phone_number'=>( row_val user, row, 'sender_phone_number'),
        'email'=>( row_val user, row, 'sender_email')
      },
      'recipient'=>{
        'company_name'=>( row_val user, row, 'recipient_company_name'),
        'attention'=>( row_val user, row, 'recipient_attention'),
        'address_line1'=>( row_val user, row, 'recipient_address_line1'),
        'address_line2'=>( row_val user, row, 'recipient_address_line2'),
        'zip_code'=>( row_val user, row, 'recipient_zip_code'),
        'city'=>( row_val user, row, 'recipient_city'),
        'country_code'=>( row_val user, row, 'recipient_country_code'),
        'phone_number'=>( row_val user, row, 'recipient_phone_number'),
        'email'=>( row_val user, row, 'recipient_email')
      }
    }
  end

  def self.row_val user, row, key
    v = row[user.import_format.attributes[key] - 1]
    if v == nil
      v = ""
    end
    return v.strip
  end


  def self.import_error msg, line_number
    {'error' => true, 'msg'=>msg + " - line #{line_number}"}
  end

  def do_submit
    uri = cargoflux_api_uri

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    if must_retry?
      #Should be PUT instead of POST. API seems broken..
      request = Net::HTTP::Put.new(uri.request_uri,
                                   initheader = {'Content-Type' =>
                                     'application/json'})
    else
      request = Net::HTTP::Post.new(uri.request_uri,
                                  initheader = {'Content-Type' =>
                                    'application/json'})
    end

    request.body = request_data.to_json
    return JSON.parse http.request(request).body
  end

end
