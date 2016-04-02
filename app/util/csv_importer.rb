require 'csv'
include Cargoflux
include GlsCountries
module CsvImporter
  
  
  
  
  def import_csv content, user
    
    encoding_options = {
      :invalid           => :replace,  # Replace invalid byte sequences
      :undef             => :replace,  # Replace anything not defined in ASCII
      :replace           => '?',        # Use a question mark for those replacements
      :universal_newline => true       # Always break lines with \n
    }
    content = content.encode(Encoding.find('ASCII'), encoding_options)

    separator = user.import_format.importer == 'interline' ? ',' : ';'
    lines = CSV.parse content, {:col_sep => separator}
    
    validation = validate_csv_values lines, user

    if !validation['error']
      lines.each do |row|
       
        if user.import_format.importer == 'interline'
          hash = interline_csv_row_hash user, row
        else
          hash = default_csv_row_hash user, row
        end
  
        create_shipment hash, user
        
      end
    end
    return validation
  end
  
  
  def validate_csv_values values, user
    if !user.import_format.complete?
      raise import_error "Import format is incomplete.", 0
    end
    values.each_with_index do |row, index|
      line_number = index + 1

      if row.length < user.import_format.min_cols
        raise import_error "No. of columns (#{row.length}) does not match import format (#{user.import_format.min_cols})", line_number
      end

      #hash = csv_row_hash user, row
      #product_code = hash['product_code']
      #if !user.products.map(&:product_code).include? product_code
      #  import_error "Invalid product code '#{product_code}'", line_number
      #end
    end
    return {'error'=>false}
  end
  
  def interline_csv_row_hash user, row
    shipment_type = row_val user, row, 'product_code'
    is_return = 0
    label_action = 'print'
    case shipment_type
    when 'A'
      product_code = 'glsb'
    when 'U'
      product_code = 'glsb'
    when 'Z'
      product_code = 'glsp'
    when '2'
      product_code = 'glsb'
      is_return = 1
      label_action = 'email'
    when 'B'
      product_code = 'glsb'
      is_return = 1
    when '4'
      raise 'Express10Service not supported.'
    when '5'
      raise 'Express12Service not supported.'
    else
      raise 'Shipment type unknown: ' + shipment_type  
    end
    
    hash = default_csv_row_hash user, row
    hash['return'] = is_return
    hash['product_code'] = product_code
    hash['label_action'] = label_action
    if product_code == 'glsp'
      hash['parcelshop_id'] = hash['recipient']['address_line2']
      hash['recipient']['address_line2'] = ''
    end
    #Package dimensions are not defined in files and GLS are not interested.
    hash['package_height'] = '10'
    hash['package_width'] = '10'
    hash['package_length'] = '10'
 
    
    hash['sender']['country_code'] = GlsCountries.get_country_code hash['sender']['country_code']
    hash['recipient']['country_code'] = GlsCountries.get_country_code hash['recipient']['country_code']
 
    return hash
  end



  def default_csv_row_hash user, row
    {
      'return'=>( row_val user, row, 'return'),
      'product_code' => ( row_val user, row, 'product_code'),
      'package_height'=>( row_val user, row, 'package_height'),
      'package_length'=>(  row_val user, row, 'package_length'),
      'package_width'=>( row_val user, row, 'package_width'),
      'package_weight'=>( row_val user, row, 'package_weight'),
      'description' => ( row_val user, row, 'description' ),
      'label_action' => ( row_val user, row, 'label_action' ),
      'amount' => ( row_val user, row, 'amount' ),
      'reference' => ( row_val user, row, 'reference' ),
      'parcelshop_id' => ( row_val user, row, 'parcelshop_id' ),
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

  def row_val user, row, key
    
    key = user.import_format.attributes[key]
    if ImportFormat.is_const_format key
      return ImportFormat.const_val key
    end
    
    intVal = Integer(key)
    if intVal < 0
      return ""
    end
    
    v = row[intVal- 1]
    if v == nil
      v = ""
    end
    return v.strip
  end
  
  def import_error msg, line_number
    {'error' => true, 'msg'=>msg + " - line #{line_number}"}.to_s
  end
  
  def create_shipment hash, user
    
    shipment = Shipment.new
    shipment.product = user.find_product hash['product_code']
    shipment.user = user
    shipment.description = hash['description']
   
    shipment.reference = hash['reference']
    shipment.parcelshop_id = hash['parcelshop_id']
    shipment.return = hash['return'] == 1 || hash['return'] == '1'
    shipment.label_action = hash['label_action']
    
  
    emptySender = true
    hash['sender'].each do |k, v|
      if v != ""
        emptySender = false
        break
      end
    end
 
    if emptySender and user.default_address
      hash['sender'] = user.default_address.attributes.except('id', 'created_at', 'updated_at')
    end
    
    
    sender = Address.new hash['sender']
    shipment.sender = sender

    recipient = Address.new hash['recipient']
    shipment.recipient = recipient

    shipment.save
    shipment = Shipment.find shipment.id
    
    package = Package.new
    package.weight = hash['package_weight'].gsub ',','.'
    package.length = hash['package_length']
    package.width = hash['package_width']
    package.height = hash['package_height']
    package.amount = hash['amount']
    package.shipment = shipment
    package.save
    
    Cargoflux.submit shipment
    
  end
  

  
end