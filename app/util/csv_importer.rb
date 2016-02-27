require 'csv'
include Cargoflux
module CsvImporter
  
  
  def import_csv content, user
    #values = CSV.parse (content.gsub ';', ',') Both comma and semicolon. Issue: Weight described with comma
    
    if user.import_format.is_interline
      arrHash = user.import_format.parse_interline content
    end
    lines = CSV.parse content, {:col_sep => ';'}
    
    validation = validate_csv_values lines, user

    if !validation['error']
      lines.each do |row|
       
        hash = csv_row_hash user, row
        
        shipment = Shipment.new
        shipment.product = Product.find_by_product_code hash['product_code']
        shipment.user = user
        shipment.package_weight = hash['package_weight'].gsub ',', '.'
        shipment.package_length = hash['package_length']
        shipment.package_width = hash['package_width']
        shipment.package_height = hash['package_height']
        shipment.description = hash['description']
        shipment.amount = hash['amount']
        shipment.reference = hash['reference']
        shipment.parcelshop_id = hash['parcelshop_id']
        
      
        sender = Address.new hash['sender']
        shipment.sender = sender

        recipient = Address.new hash['recipient']
        shipment.recipient = recipient

        shipment.save
        shipment = Shipment.find shipment.id
        
        Cargoflux.submit shipment
      end
    end
    return validation
  end
  
  
  def validate_csv_values values, user
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
        import_error "Invalid product code '#{product_code}'", line_number
      end
    end
    return {'error'=>false}
  end

  def csv_row_hash user, row
    {
      'return'=>( row_val user, row, 'return'),
      'product_code' =>( row_val user, row, 'product_code'),
      'package_height'=>( row_val user, row, 'package_height'),
      'package_length'=>(  row_val user, row, 'package_length'),
      'package_width'=>( row_val user, row, 'package_width'),
      'package_weight'=>( row_val user, row, 'package_weight'),
      'description' => ( row_val user, row, 'description' ),
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
    v = row[user.import_format.attributes[key] - 1]
    if v == nil
      v = ""
    end
    return v.strip
  end
  
  def import_error msg, line_number
    {'error' => true, 'msg'=>msg + " - line #{line_number}"}
  end

  
end