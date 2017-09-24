using PatternMatch
include ApplicationHelper
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
  
  def get_customer_data id
    return get(BASE_ENDPOINT + "customers/#{id}")
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
  
end
