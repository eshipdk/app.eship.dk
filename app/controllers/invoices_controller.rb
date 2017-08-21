class InvoicesController < ApplicationController
  before_filter :authenticate_admin, except: [:export_rows]
  before_filter :authenticate_user, only: [:export_rows]
  layout 'blank', only: [:export_rows]  
  respond_to :xlsx
  
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
    if invoice.editable?   
      invoice.shipments.each do |s|
        s.invoiced = false
        s.invoice = nil
        s.save
      end
      invoice.additional_charges.each do |c|
        c.invoice = nil
        c.save
      end
      invoice.destroy
    else
      flash[:error] = 'Cannot delete this invoice.'
    end
   
    redirect_to :back
  end
  
  def export_rows
    @invoice = Invoice.find params[:invoice_id]
    
    if !@current_user.admin? and @invoice.user != @current_user
      redirect_to '/'
      return
    end
    respond_to do |format|
      format.xlsx
    end

    response.headers['Content-Disposition'] = "attachment; filename=#{@invoice.pretty_id}-rows.xlsx"    
  end
  
end
