class AdminController < ApplicationController
  before_filter :authenticate_admin
  before_filter :filter_dates, :only => :dashboard

  def dashboard
    
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
      ids << line[0]
    end
    
    all_shipments = Shipment.where(:cargoflux_shipment_id => ids)
    known_ids = all_shipments.map{|s| s.cargoflux_shipment_id}
    @unknown = ids.reject{|x| known_ids.include? x}
    @incomplete = all_shipments.where.not(:shipping_state => 3)
  end
  
  def update_shipping_states
    Shipment.update_pending_shipping_states
    redirect_to admin_tools_path
  end
  
  def automatic_invoicing
    User.perform_automatic_invoicing
    redirect_to admin_tools_path
  end

end