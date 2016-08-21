class InvoicesController < ApplicationController
  before_filter :authenticate_admin
  
  
  def show
    @invoice = Invoice.find params[:id]
    @shipments_link = invoice_shipments_path @invoice
    @admin = true
  end
  
  def shipments
    @invoice = Invoice.find params[:invoice_id]
    @shipments = @invoice.shipments
    @admin = true
  end
  
  def destroy
    invoice = Invoice.find(params[:id])
    shipments = invoice.shipments
    for shipment in shipments do
      shipment.invoiced = false
      shipment.invoice = nil
      shipment.save
    end
    invoice.destroy
    redirect_to :back
  end
  
  
end
