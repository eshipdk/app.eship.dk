using PatternMatch
include ApplicationHelper
module Economic
  
  BASE_ENDPOINT = 'https://restapi.e-conomic.com/'
  DRAFTS_ENDPOINT = 'https://restapi.e-conomic.com/invoices/drafts'
  
  AST = 'nBpsmoZrlyGF606BmjraJlHRqjUvrh4dyvBOk5tXhyU1'
  AGT = 'BqfwngGDN3IrSjGXZoTvGqtHuv575f0E6WBJhIlk4BY1'
  
  
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
  
  
  def submit_invoice invoice
    match(invoice_payload(invoice)) do
      with(_[:error, issue]) do
        [:error, issue]
      end
      with payload do
        #raise res.to_json.to_s
        res = post(BASE_ENDPOINT + "invoices/drafts",  payload)
        if res.key?('errorCode')
          [:error, res]
        else
          invoice.gross_amount = res['grossAmount']
          invoice.sent_to_economic = true
          invoice.save
          res
        end
      end
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
        "paymentTermsNumber"=> 1,
        "daysOfCredit"=> 14,
        "name"=> "Lobende maned 14 dage",
        "paymentTermsType"=> "invoiceMonth"
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
  
  def get_invoice_data invoice
    get(BASE_ENDPOINT + "invoices/booked/#{invoice.economic_id}")
  end

  def get_pdf_data invoice
    data = get_invoice_data invoice
    return get_raw(data['pdf']['download'])
  end

  
  def get_raw url
    endpoint = URI.parse url
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(endpoint.request_uri,
                                  initheader = {
                                     'Content-Type' =>'application/json',
                                     'X-AppSecretToken' => AST,
                                     'X-AgreementGrantToken'=> AGT,
                                     'accept' => "application/json"})
     http.request(request).body
  end
  
  def get url                      
     JSON.parse(get_raw(url))
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
