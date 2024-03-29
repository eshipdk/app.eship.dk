using PatternMatch
include ApplicationHelper
include CountryNames
module Economic
  
  BASE_ENDPOINT = 'https://restapi.e-conomic.com/'
  DRAFTS_ENDPOINT = "#{BASE_ENDPOINT}/invoices/drafts"
  BOOKED_ENDPOINT = "#{BASE_ENDPOINT}/invoices/booked"
  
  AST = 'nBpsmoZrlyGF606BmjraJlHRqjUvrh4dyvBOk5tXhyU1' # App secret token for internal use
  def AST_Customer
    'nBpsmoZrlyGF606BmjraJlHRqjUvrh4dyvBOk5tXhyU1' # App secret token for customer integration
  end
  AGT = 'BqfwngGDN3IrSjGXZoTvGqtHuv575f0E6WBJhIlk4BY1' # Agreement grant token for internal use
  
  
  def get_customer_options
    h = {'None' => nil}
    get_customers.each{|x| h[x['name']] = x['customerNumber']}
    h
  end
  
  def get_customers
    customers = get(BASE_ENDPOINT + 'customers?skippages=0&pagesize=1000')
    customers['collection']
  end
  
  def get_customer_name id
    customer = get(BASE_ENDPOINT + "customers/#{id}")
    customer['name']
  end  
  
  def get_customer_data id, ast = AST, agt = AGT
    return get(BASE_ENDPOINT + "customers/#{id}", ast, agt)
  end
  
  def update_user_address user
    data = get_customer_data user.economic_customer_id  
    addr = user.contact_address
    addr.company_name = data['name']
    addr.attention = ''
    addr.address_line1 = data['address']
    addr.address_line2 = ''
    addr.country_code = data['country']
    addr.zip_code = data['zip']
    addr.city = data['city']
    addr.phone_number = data['mobilePhone']
    addr.email = data['email']
    addr.save    
  end
  
  
  def submit_invoice invoice, capture = true
    match(invoice_payload(invoice)) do
      with(_[:error, issue]) do
        [:error, issue]
      end
      with payload do
        #raise res.to_json.to_s
        res = post(DRAFTS_ENDPOINT,  payload)
        if res.key?('errorCode')
          [:error, res]
        else          
          invoice.gross_amount = res['grossAmount']
          invoice.economic_draft_id = res['draftInvoiceNumber']
          invoice.sent_to_economic = true
          invoice.save
          if capture            
            Economic.capture_invoice invoice
          else
            res  
          end          
        end
      end
    end
  end
  
  def self.capture_invoice invoice    
    payload = {
      'draftInvoice' =>{
        'draftInvoiceNumber' => invoice.economic_draft_id
      },
      'sendBy' => 'none'
    }
    res = post(BOOKED_ENDPOINT, payload)
    if res.key?('errorCode')
      [:error, res]
    else
      invoice.economic_id = res['bookedInvoiceNumber']
      invoice.pdf_download_key = rand(36**64).to_s(36)
      invoice.save
      invoice.send_email
      res
    end
  end
  
  def invoice_payload invoice
    
    customerId = invoice.user.economic_customer_id
    if customerId == nil
      return [:error, 'Customer has not been linked to an e-conomic customer.']
    end
    
    netAmount = invoice.amount.round(2).to_f
    grossAmount = invoice.gross_amount.round(2).to_f
    vatAmount = (grossAmount - netAmount).round(2).to_f
    customer = invoice.customer.contact_address
    
    if invoice.customer.invoices.count > 1
      # The last invoice created before this one
      prev_invoice = invoice.customer.invoices.where(['created_at < ?', invoice.created_at]).order(created_at: :desc).first
      notes = "Periode: #{print_date prev_invoice.created_at} til #{print_date invoice.created_at}"
    else
      notes = "Periode: #{print_date invoice.user.created_at} til #{print_date invoice.created_at}"
    end
    notes = notes + "\nModtager af services:\n#{customer.company}\n#{customer.address_line1}\n#{customer.address_line2}\n#{customer.zip_code} #{customer.city}"
    
    customerData = get_customer_data customerId    
    
    i = 0
    lines = invoice.rows.order(:description).map{|x| i+=1;
        {'lineNumber' => i,
         "product" => {
           "productNumber" => x.product_code
         },
         "description" => x.description, 
         "unitNetPrice" => x.unit_price.round(2).to_f,
         "quantity" => x.qty
        }}
    
    data = {
    "date"=> invoice.created_at.to_date.to_s,
    "currency"=> "DKK",
    "exchangeRate"=> 100,
    "netAmount"=> netAmount,
    "netAmountInBaseCurrency"=> netAmount,
    "grossAmount"=> grossAmount,
    "marginInBaseCurrency"=> 0,
    "marginPercentage"=> 0.0,
    "vatAmount"=> vatAmount,
    "roundingAmount"=> 0.00,
    "costPriceInBaseCurrency"=> 0,
    "notes" => {
      "textLine1" => notes
    },
    "paymentTerms"=> {
        "paymentTermsNumber"=> customerData['paymentTerms']['paymentTermsNumber']        
    },
    "customer"=> {
        "customerNumber"=> customerId
    },
    "recipient"=> { # Use customer data from e-conomic as recipient
        "name"=> customerData['name'],
        "address"=>  customerData['address'],
        "zip"=> customerData['zip'],
        "city"=> customerData['city'],
        "vatZone"=> {
            "name"=> "Domestic",
            "vatZoneNumber"=> 1,
            "enabledForCustomer"=> true,
            "enabledForSupplier"=> true
        }
    },
    "delivery"=> {
        "address"=>  customer.address_line1 + "\n" + customer.address_line2,
        "zip"=> customer.zip_code.to_s,
        "city"=> customer.city,
        "country"=> customer.country_code,
        "deliveryDate"=> invoice.created_at.to_date.to_s
    },
    "references"=> {
        "other"=> invoice.id.to_s
    },
    "layout"=> {
        "layoutNumber"=> 19
    },
    "lines"=> lines
  }
  end
  
  def identify_booked_invoice invoice
    res = get(BASE_ENDPOINT + "invoices/booked?filter=references.other$eq:#{invoice.id}")
    col = res['collection']
    if col.any?
      invoice.economic_id = col[0]['bookedInvoiceNumber']
      invoice.gross_amount = col[0]['grossAmount']
      invoice.save
    else
      [:error, "e-conomic invoice with reference #{invoice.id} could not be found."]
    end
  end
  
  def get_invoice_data invoice, ast = AST, agt = AGT
    if invoice.is_a?(Invoice)
      id = invoice.economic_id
    else
      id = invoice
    end
    get(BASE_ENDPOINT + "invoices/booked/#{id}", ast, agt)
  end

  # You can't lookup by actual id provided by webhook. Instead,
  # get a list and find the one with the matching ID...
  def get_invoice_draft_data_by_handle invoice_id, ast = AST, agt = AGT
    drafts = get(BASE_ENDPOINT + "invoices/drafts", ast, agt)
    drafts['collection'].each do |draft|
      if draft['soap']['currentInvoiceHandle']['id'].to_i == invoice_id.to_i
        id = draft['draftInvoiceNumber']
        return get_invoice_draft_data id, ast, agt
      end
    end
    return false
  end

  def self.get_product_data product_number, ast = AST, agt = AGT
    get BASE_ENDPOINT + "products/#{product_number}", ast, agt
  end

  def get_invoice_draft_data id, ast = AST, agt = AGT
     get(BASE_ENDPOINT + "invoices/drafts/#{id}", ast, agt)
  end


  def get_pdf_data invoice
    data = get_invoice_data invoice
    return get_raw(data['pdf']['download'])
  end

  
  def get_raw url, ast = AST, agt = AGT
    endpoint = URI.parse url
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
        
    request = Net::HTTP::Get.new(endpoint.request_uri,
                                  initheader = {
                                     'Content-Type' =>'application/json',
                                     'X-AppSecretToken' => ast,
                                     'X-AgreementGrantToken'=> agt,
                                     'accept' => "application/json"})
     http.request(request).body
  end
  
  def get url, ast = AST, agt = AGT           
     JSON.parse(get_raw(url, ast, agt))
  end
  
  def post url, payload

    endpoint = URI.parse url
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(endpoint.request_uri,
                                  initheader = {
                                     'Content-Type' =>'application/json',
                                     'X-AppSecretToken' => AST,
                                     'X-AgreementGrantToken'=> AGT,
                                     'accept' => "application/json"})
                   
     request.body = payload.to_json                   
     JSON.parse http.request(request).body
  end

  def put url, payload, ast, agt

    endpoint = URI.parse url
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    
    request = Net::HTTP::Put.new(endpoint.request_uri,
                                  initheader = {
                                     'Content-Type' =>'application/json',
                                     'X-AppSecretToken' => ast,
                                     'X-AgreementGrantToken'=> agt,
                                     'accept' => "application/json"})
                   
     request.body = payload.to_json                   
     JSON.parse http.request(request).body
  end

  
  def self.data_import_product_data data, user
    lines = data['lines']
    lines.each do |line|
      product_code = line['product']['productNumber']
      if product_code.start_with? 'eship_dataimport'
        return Economic.parse_import_product_data line, user
      end
    end
    return nil
  end

  def self.parse_import_product_data line, user

    # If the product code is exactly eship_dataimport we apply default config. I.e.
    # the dataimport product with defualt dimensions and extracting qty from the qty field.
    # Otherwise we lookup the description of the product through the API and attempt to
    # parse it as JSON. If it is properly formated we use it, otherwise we just apply the
    # defualt configuration as above.
    
    if line['product']['productNumber'] != 'eship_dataimport'
      product_data = Economic.get_product_data line['product']['productNumber'], Economic.AST_Customer, user.economic_api_key
      desc = product_data['description']
      if desc.start_with? '{' and desc.end_with? '}'
        return JSON.parse desc
      end      
    end

    package = Economic.default_package
    package['amount'] = line['quantity'].to_i
    return {
      'product' => 'cfdataimport',
      'packages' => [
        package
      ]
    }    
  end

  def self.default_package
    {
      'width' => 1,
      'height' => 1,
      'length' => 1,
      'weight' => 1,
      'amount' => 1
    }
  end

  def self.book_by_invoice_data user, data, draft_id = false
    
    if data['httpStatusCode'] == 401
      res = 'Denied access to economic'
      return [:error, res]
    end
    
    if not data.key?('lines')
      res = "Unexpected response from economic: #{data.to_s}"
      return [:error, res]
    end        

    product_data = Economic.data_import_product_data data, user
    if not product_data
      return false
    end
        
    begin
      product = user.find_product product_data['product']
    rescue => ex
      res = 'User does not have access to dataimport product'
      return [:error, res]
    end
      
    if not user.default_address
      res = 'No sender address configured in eShip. Please configure default address in the address book.'
      return [:error, res]
    end

    customer_id = data['customer']['customerNumber']
    customer_data = Economic.get_customer_data customer_id, Economic.AST_Customer, user.economic_api_key
    
    sender = user.default_address
    
    recipient = Address.new
    recipient.company_name = data['recipient']['name']
    recipient.attention = data['recipient']['name']
    recipient.address_line1 = data['delivery']['address']
    recipient.country_code = CountryNames.get_code_from_danish data['delivery']['country']
    recipient.zip_code = data['delivery']['zip']
    recipient.city = data['delivery']['city']         
    recipient.phone_number = customer_data['telephoneAndFaxNumber']
    recipient.email = customer_data['email']    
    recipient.save
        
    shipment = Shipment.new
    shipment.user = user
    shipment.product = product
    shipment.sender = sender
    shipment.recipient = recipient
    if draft_id
      shipment.economic_draft_id = draft_id
    end
    shipment.save
    
    product_data['packages'].each do |pdata|
      package = Package.new
      package.width = pdata['width']
      package.length = pdata['length']
      package.height = pdata['height']
      package.weight = pdata['weight']
      package.amount = pdata['amount']
      package.shipment = shipment
      package.save
    end    
    
    # Label customers will edit their bookings directly in CF.
    # Shipment customers will do it in eship.
    if user.customer_type == 'label'
      if shipment.price_configured?
        Cargoflux.submit shipment
      else
        shipment.status = 'failed'
        shipment.save
      end
    else
      shipment.status = :initiated
      shipment.save
    end
    
    shipment.reload

    return shipment
  end
  
  def self.create_booking_from_invoice_captured user, invoice_id
    data = Economic.get_invoice_data invoice_id, Economic.AST_Customer, user.economic_api_key
    if data['errorCode'] == 'E06000'
      res = "Cannot find invoice id #{invoice_id}"
      return [:error, res]     
    end

    return Economic.book_by_invoice_data user, data
  end


  def self.create_booking_from_invoice_updated user, invoice_id
    data = Economic.get_invoice_draft_data_by_handle invoice_id, Economic.AST_Customer, user.economic_api_key
    if not data
      res = "Cannot find invoice id #{invoice_id}: #{data}"
      return [:error, res]
    end
    shipment = Economic.book_by_invoice_data user, data, data['draftInvoiceNumber']
    
    # Remove the dataimport products from the given draft
    if shipment and shipment.economic_draft_id
      Economic.update_import_in_draft shipment
    end
  end

  def self.update_import_in_draft shipment
    user = shipment.user
    data = Economic.get_invoice_draft_data shipment.economic_draft_id, Economic.AST_Customer, user.economic_api_key

    lines = data['lines']
    new_lines = []
    lines.each do |line|     
      if line['product']['productNumber'].start_with? 'eship_dataimport'

      else
        new_lines.push line
      end
    end

    data['lines'] = new_lines
    put BASE_ENDPOINT + "invoices/drafts/#{shipment.economic_draft_id}", data,
        Economic.AST_Customer, user.economic_api_key
    
  end
  
end
