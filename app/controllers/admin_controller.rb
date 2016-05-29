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

      row['value'], issues = c.calc_value shipments
      if issues
          totalIssues = totalIssues + issues
      end
      
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

end