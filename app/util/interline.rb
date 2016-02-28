
module Interline
  
  
  def parse_interline content, user
    
    rows = CSV.parse content
    
    
    default_length = 20 - (user.import_format.interline_default_mail_advertising ? 1 : 0) #If line indicates default consignor
    alternative_length = default_length + 7 #If line contains alternative consignor
    
    arr_hash = []
    line = 0
    rows.each do |row|
      line += 1
      
      if row.length == default_length
        default_consignor = true
      else
        if row.length == alternative_length
          default_consignor = false
        else
          raise "Row " + line.to_s + " contains " + row.length.to_s + " cells but should contain " + default_length + 
            " (for default consignor) or " + alternative_length + " (alternative consignor). Using InterLine format. Separator: ','"
        end
      end
      
      if row.length != 28
        
      end
      arr_hash.push interline_csv_row_hash row
    end
    
    raise arrHash.to_s
  end
  
  def interline_csv_row_hash row, default_consignor
       {
#      'return'=>( row_val user, row, 'return'),
#      'product_code' =>( row_val user, row, 'product_code'),
#      'package_height'=>( row_val user, row, 'package_height'),
#      'package_length'=>(  row_val user, row, 'package_length'),
#      'package_width'=>( row_val user, row, 'package_width'),
#      'package_weight'=>( row_val user, row, 'package_weight'),
#      'description' => ( row_val user, row, 'description' ),
#      'amount' => ( row_val user, row, 'amount' ),
#      'reference' => ( row_val user, row, 'reference' ),
#      'parcelshop_id' => ( row_val user, row, 'parcelshop_id' ),
#      'sender'=>{
#        'company_name'=>(  row_val user, row, 'sender_company_name'),
#        'attention'=>( row_val user, row, 'sender_attention'),
#        'address_line1'=>( row_val user, row, 'sender_address_line1'),
#        'address_line2'=>( row_val user, row, 'sender_address_line2'),
#        'zip_code'=>( row_val user, row, 'sender_zip_code'),
#        'city'=>( row_val user, row, 'sender_city'),
#        'country_code'=>( row_val user, row, 'sender_country_code'),
#        'phone_number'=>( row_val user, row, 'sender_phone_number'),
#        'email'=>( row_val user, row, 'sender_email')
#      },
      'recipient'=>{
        'company_name'=> row[1],
#        'attention'=>( row_val user, row, 'recipient_attention'),
#        'address_line1'=>( row_val user, row, 'recipient_address_line1'),
#        'address_line2'=>( row_val user, row, 'recipient_address_line2'),
#        'zip_code'=>( row_val user, row, 'recipient_zip_code'),
#        'city'=>( row_val user, row, 'recipient_city'),
#        'country_code'=>( row_val user, row, 'recipient_country_code'),
#        'phone_number'=>( row_val user, row, 'recipient_phone_number'),
#        'email'=>( row_val user, row, 'recipient_email')
      }
    }
  end

  
end