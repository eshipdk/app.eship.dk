class ImportFormat < ActiveRecord::Base
  belongs_to :user
  before_save :default_values

  def complete?
    cols.values.each do |v|
      if !v
        return false
      end
    end
    return true
  end
  
  
  def default_values
    if is_interline
      i = 1
      cols.keys.each do |k|
        self[k] = i
        i = i + 1
      end
    end
  end

  def min_cols
    return cols.values.max
  end

  def cols
    return attributes.except('id','created_at','updated_at', 'user_id', 'is_interline')
  end
  
  
  def parse_interline content
    
    rows = CSV.parse content
    
    arrHash = []
    line = 0
    rows.each do |row|
      line += 1
      raise row.to_s
      if row.length != 28
        raise "Row " + line.to_s + " contains " + row.length.to_s + " cells but should contain 28 (InterLine format). Separator: ','"
      end
      arrHash.push interline_csv_row_hash row
    end
    
    raise arrHash.to_s
  end
  
private
  
  def interline_csv_row_hash row
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
