class InvoicesController < ApplicationController
  before_filter :authenticate_admin
  
  
  
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
