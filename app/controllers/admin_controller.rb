include Reporting
require 'csv'
require 'roo'
include CsvImporter
class AdminController < ApplicationController
  before_filter :authenticate_admin
  before_filter :filter_dates, :only => :dashboard

  def dashboard

    @booking_report = Reporting.generate_booking_report(@dateFrom, @dateTo)
    @invoice_report = Reporting.generate_invoice_report(@dateFrom, @dateTo)
    return
    customers = User.customer
    #customers = User.all
    @customerData = []
    @nShipments = 0
    @value = 0.0
    @nInvoices = 0
    @totalInvoiced = 0.0
    totalIssues = []
    for c in customers do
      shipments = c.shipments.complete.where('created_at > ?', @dateFrom).where('created_at < ?', @dateTo)
      invoices = c.invoices.where('created_at > ?', @dateFrom).where('created_at < ?', @dateTo)
      row = {'email' => c.email, 'booked' => shipments.count, 'invoices' => invoices.count, 'invoiced' => invoices.sum(:amount)}

      cost, row['value'], fee = c.balance
      
      @nShipments = @nShipments + row['booked']
      @value = @value + row['value']
      @nInvoices = @nInvoices + row['invoices']
      @totalInvoiced = @totalInvoiced + row['invoiced']
      @customerData.push(row)
    end
    
    if totalIssues
      #flash[:error] = totalIssues
    end
    
  end

  def show_shipment
    @shipment = Shipment.find params[:id]
    @disable_actions = true
    @shipment.update_shipping_state
    render 'shipments/show'
  end
  
  def tools
    @n_response_pending = Shipment.where(:status => 1).count
  end
  
  
  
  def verify_billable_shipments
    
    begin
      uploaded_file = params[:file]
      file_content = uploaded_file.read
      lines = CSV.parse file_content,  {:col_sep => ';', :quote_char => "\x00"}
      lines.shift
    rescue Exception => e
      flash[:error] = e.to_s
      redirect_to admin_tools_path
      return
    end
    
    ids = []
    lines.each do |line|
      id = line[0]
      if id
        ids << line[0]
      end
    end

    
    all_shipments = Shipment.where(:cargoflux_shipment_id => ids)
    known_ids = all_shipments.map{|s| s.cargoflux_shipment_id}
    @unknown = ids.reject{|x| known_ids.include? x}
    @incomplete = all_shipments.where.not(:shipping_state => 3)
  end
  
  def update_shipping_states
    Shipment.update_pending_shipping_states
    redirect_to :back
  end
  
  def update_booking_states
    Shipment.update_pending_booking_states
    redirect_to :back
  end
  
  def automatic_invoicing
    User.perform_automatic_invoicing
    redirect_to :back
  end
  
  def fetch_economic_data
    Invoice.identify_economic_ids
    Invoice.fetch_economic_data
    redirect_to :back
  end
  
  def process_additional_charges
    uploaded_file = params[:file]
    spreadsheet = Roo::Spreadsheet.open(uploaded_file)    
    
    @charges = []
    header = spreadsheet.row(1).map{|x| x.downcase}
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      awb = row['pakke nr.']
      
      if awb
        service = row['beskrivelse']
        cost = row['beløb']
        price = row['pris']
        if not price
          price = cost
        end
        shipment = Shipment.where(awb: awb).first!
        user = shipment.user
        @charges.push(ChargeDraft.new(shipment, user, cost, price, service))
      end      
    end
  end
  
  def approve_additional_charges
    user_ids = params[:user]
    shipment_ids = params[:shipment]
    services = params[:service]
    costs = params[:cost]
    prices = params[:price]
    (0..user_ids.length-1).each do |i|
      charge = AdditionalCharge.new      
      shipment = Shipment.find shipment_ids[i]      
      charge.user_id = user_ids[i]
      charge.cost = costs[i]
      charge.price = prices[i]
      charge.description = "#{shipment.awb}: #{services[i]}"
      charge.product_code = 'service_charge'
      charge.shipment_id = shipment.id
      charge.save
    end
    flash[:success] = "#{user_ids.length} additional service charges saved."
    redirect_to admin_tools_path
  end
  
  def import_ftp_uploads
    CsvImporter.import_ftp_uploads
    redirect_to :back
  end

end
