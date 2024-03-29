require 'csv'
include Cargoflux
include GlsCountries
module CsvImporter
  

  
  def self.import_csv content, user

    delimiter = user.import_format.delimiter
    begin
      lines = CSV.parse (content.gsub(/\r\n?/, "\n")), {:col_sep => delimiter, :skip_blanks => true}
    rescue StandardError => e
      raise CsvImportException.new(e.to_s)
    end
    validation = validate_csv_values lines, user


    # Parse shipments from csv
    shipments = []
    if !validation['error']
      i = 0
      lines.each do |row|
        i += 1
        if i <= user.import_format.header_lines
          next
        end
        
        if user.import_format.importer == 'interline'
          hash = interline_csv_row_hash user, row, i
          interline_service = hash['description']
          hash['description'] = ''
        else
          hash = default_csv_row_hash user, row
        end  
        shipments.push(create_shipment(hash, user))

        
        if user.import_format.importer == 'interline'
          if interline_service == 'B'
            hash['product_code'] = 'glsb'
            hash['return'] = 1
            hash['recipient'], hash['sender'] = hash['sender'], hash['recipient']
            shipments.push(create_shipment(hash, user))
          end         
        end

        
      end
    end

    # Cross-reference shipments
    if user.import_format.cross_reference_flag
      shipments = CsvImporter.cross_reference_shipments shipments
    end

    
    # Submit shipments
    CsvImporter.submit_shipments shipments
    
    return validation
  end

  def self.cross_reference_shipments shipments
    
    by_ref = {}
    unique_shipments = []

    # Group shipments by reference. Shipments with no
    # reference are automatically unique
    shipments.each do |s|
      ref = s.reference
      if ref.to_s.strip != ''
        if by_ref.key? ref
          by_ref[ref].push(s)
        else
          by_ref[ref] = [s]
        end
      else
        unique_shipments.push(shipment)
      end
    end

    # Reduce each group to a single shipment by
    # moving all packages to one shipment and
    # destroying the remaining shipments
    by_ref.keys.each do |ref|
      arr = by_ref[ref]
      s1 = arr.shift
      while (s2 = arr.shift)
        s2.packages.each do |p|
          p.shipment = s1
          p.save
        end
        s2 = s2.reload
        s2.destroy
      end
      unique_shipments.push(s1)
    end
    
    return unique_shipments
  end

  def self.submit_shipments shipments
    shipments.each do |shipment|
      if shipment.price_configured?
        Cargoflux.submit shipment
      else
        shipment.status = 'failed'
        shipment.label_pending = true
        shipment.save
      end
    end
  end
  
  def self.validate_csv_values values, user
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
  
  def self.interline_csv_row_hash user, row, line
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
    when 'M'
      product_code = 'OC_glsproc'
    when 'R'
      product_code = 'OC_glsproc'
      is_return = 1
    when '4'
      raise import_error 'Express10Service not supported.', line
    when '5'
      raise import_error 'Express12Service not supported.', line
    else
      raise import_error 'Shipment type unknown: ' + shipment_type, line
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
    
    if is_return == 1
      hash['recipient'], hash['sender'] = hash['sender'], hash['recipient']
    end
  
    if hash['description'] == 'C'
      hash['delivery_instructions'] = hash['remarks']
      hash['remarks'] = ''
    else
      hash['delivery_instructions'] = ''
    end
 
    return hash
  end



  def self.default_csv_row_hash user, row
    {
      'return'=>( row_val user, row, 'return'),
      'product_code' => ( row_val user, row, 'product_code'),
      'package_height'=>( row_val user, row, 'package_height'),
      'package_length'=>(  row_val user, row, 'package_length'),
      'package_width'=>( row_val user, row, 'package_width'),
      'package_weight'=>( row_val user, row, 'package_weight'),
      'description' => ( row_val user, row, 'description' ),
      'remarks' => ( row_val user, row, 'remarks' ),
      'delivery_instructions' => ( row_val user, row, 'delivery_instructions' ),
      'label_action' => ( row_val user, row, 'label_action' ),
      'amount' => ( row_val user, row, 'amount' ),
      'reference' => ( row_val user, row, 'reference' ),
      'parcelshop_id' => ( row_val user, row, 'parcelshop_id' ),
      'customs_amount' => ( row_val user, row, 'customs_amount' ),
      'customs_currency' => (row_val user, row, 'customs_currency' ),
      'customs_code' => ( row_val user, row, 'customs_code' ),
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
    return user.import_format.row_val row, key
  end
  
  def self.import_error msg, line_number
    CsvImportException.new(msg + " - line #{line_number}")
  end
  
  def self.create_shipment hash, user
    
    shipment = Shipment.new
    shipment.product = user.find_product hash['product_code']
    shipment.user = user
    shipment.description = hash['description']
    shipment.remarks = hash['remarks']
    shipment.delivery_instructions = hash['delivery_instructions']
    shipment.reference = hash['reference']
    shipment.parcelshop_id = hash['parcelshop_id']
    shipment.return = hash['return'] == 1 || hash['return'] == '1'
    shipment.label_action = hash['label_action']

    shipment.customs_amount = hash['customs_amount'] ? hash['customs_amount'].to_f : nil
    shipment.customs_currency = hash['customs_currency']
    shipment.customs_code = hash['customs_code']
    
  
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

    return shipment    
  end
  
  def self.decode_content content
    # Issue: How do we determine the input encoding?
    # There exists no correct solution. Instead, we attempt to guess it using a naive heuristic.
    # If the input text is utf-8 encoded then decoding it as ascii will probably result in
    # a more complex (measured as longer) output than the original input.
    content_utf8 = content.force_encoding(Encoding::UTF_8).encode(Encoding::UTF_8)
    content_ascii = content.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8)
    if content_utf8.length == content_ascii.length
      content = content_ascii
    else
      content = content_utf8
    end
    return content  
  end
      
  def self.import_ftp_uploads

    pid = Process.pid
    User.where(:enable_ftp_upload => true).each do |user|      
      dir = "/var/ftp_upload/#{user.ftp_upload_user}"  
      filenames = Dir.glob("#{dir}/*.csv") # only consider csv files!
      filenames.each do |filename|
        # If the file is present in the lists in multiple threads there will be a race condition
        # s.t. only the first process lock it will get to process it. Thread safety is
        # provided assuming atomicity of file renaming which should be guaranteed by OS.
        inner_filename = filename
        locked_filename = "#{filename}.lock_#{pid}"
        begin
          age = (Time.now - File.stat(filename).mtime).to_i
          if age > 5 # Wait at least 5 seconds to ensure upload is finished
            File.rename(filename, locked_filename)
            inner_filename = locked_filename
            content = decode_content IO.binread(inner_filename)
            import_csv content, user
            File.delete(inner_filename)
          end
        rescue => e
          if e.to_s == 'CsvImportException'
            estr = "CsvImportException: #{e.issue}"
          else
            estr = e.to_s
          end
          Rails.logger.warn "#{Time.now.utc.iso8601} EXCEPTION IMPORTING FILE #{filename}}: #{estr}"
          issue = "#{estr}: #{e.backtrace.join("\n")}"
          Rails.logger.warn issue
          SystemMailer.ftp_upload_import_failed(filename, issue).deliver_now
          File.rename inner_filename, "#{filename}.fail-backup"
          File.open("#{filename}.error", 'w+') do |f|
            f.write(estr)
          end
        end       
      end      
    end    
  end
  
  # crontab only has 1 minute granularity but we want 5 second intervals on
  # import ftp uploads. Use crontab to spawn a new process every one minute
  # that runs for approximately one minute before terminating. 
  def self.import_ftp_uploads_60s_daemon
    tstart = Time.now()
    while Time.now() - tstart < 55
      CsvImporter.import_ftp_uploads
      sleep 5
    end
  end
end
