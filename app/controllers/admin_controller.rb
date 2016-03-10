class AdminController < ApplicationController
  before_filter :authenticate_admin

  def dashboard
    
    from = params[:from]
    to = params[:to]
    
    if from
      @dateFrom = DateTime.now.change(day: from[:day].to_i, month: from[:month].to_i, year: from[:year].to_i)
      @dateTo = DateTime.now.change(day: to[:day].to_i, month: to[:month].to_i, year: to[:year].to_i)
    else
      @dateFrom = DateTime.now
      @dateTo = DateTime.now
    end
    
    customers = User.customer
    @customerData = []
    @nShipments = 0
    @value = 0.0
    @nInvoices = 0
    @totalInvoiced = 0.0
    for c in customers do
      shipments = c.shipments.complete.where('created_at > ?', @dateFrom.beginning_of_day).where('created_at < ?', @dateTo.end_of_day)
      invoices = c.invoices.where('created_at > ?', @dateFrom.beginning_of_day).where('created_at < ?', @dateTo.end_of_day)
      row = {'email' => c.email, 'booked' => shipments.count, 'value' => (c.calc_value shipments), 'invoices' => invoices.count, 'invoiced' => invoices.sum(:amount)}
      
      @nShipments = @nShipments + row['booked']
      @value = @value + row['value']
      @nInvoices = @nInvoices + row['invoices']
      @totalInvoiced = @totalInvoiced + row['invoiced']
      @customerData.push(row)
    end
    
    
    
  end

end