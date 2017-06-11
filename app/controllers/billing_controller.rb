include Economic
include Epay
using PatternMatch
class BillingController < ApplicationController
  before_filter :authenticate_admin
  
  
  def user
    @user = User.find(params[:id])
    @invoices = @user.invoices.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end
  
  def edit_prices
    @user = User.find(params[:id])
  end
  
  def edit_additional_charges
    @user = User.find(params[:id])
  end
  
  def update_prices
    @user = User.find(params[:id])
    data = params.require(:shipments)
    data.each do |shipment_id, row|
      shipment = Shipment.find shipment_id
      if shipment.user != @user
        raise 'Unknown logical error..'
      end
      shipment.final_price = row['price'] == '' ? shipment.price : row['price'].to_f
      shipment.final_diesel_fee = row['diesel_fee'] == '' ? shipment.diesel_fee : row['diesel_fee'].to_f
      shipment.save
    end
    redirect_to :action => :user
  end
  
  def update_additional_charges
    @user = User.find(params[:id])
    trash = params[:delete]
    if trash == nil
      trash = []
    end
    ids = params[:cid] - trash
    prices = params[:price]
    
    trash.each do |id|
      AdditionalCharge.find(id).destroy
    end
    
    (0..ids.length - 1).each do |i|
      c = AdditionalCharge.find(ids[i])
      c.price = prices[i]
      c.save
    end
    
    redirect_to :action => :user
  end
  
  def invoice
    user = User.find(params[:user_id])
    begin
      user.do_invoice
    rescue PriceConfigException => e
      flash[:error] = e.issue
    end
    redirect_to user_billing_path(user)
  end
  
  # Submit invoice draft to e-conomic
  def submit_invoice
    invoice = Invoice.find(params[:id])
    if invoice.editable?
      match(Economic.submit_invoice(invoice)) do
        with(_[:error, issue]) do
          flash[:error] = issue
        end
        with(res) do
        end
      end
    else
      flash[:error] = 'This invoice is already booked.'
    end
    redirect_to user_billing_path(invoice.user)
  end
  
  def capture_invoice
    invoice = Invoice.find(params[:id])
    if invoice.capturable?
      match(Epay.capture_invoice(invoice)) do
        with(_[:error, issue]) do
          flash[:error] = issue
        end
        with(res) do
        end
      end
    else
      flash[:error] = 'This invoice can not be captured.'
    end
    redirect_to :back
  end
  
  def overview
     # Bad in-memory ordering. Todo: put uninvoiced shipment count in database
    @users = User.customer.sort_by  {|user| user.n_uninvoiced_shipments}.reverse.find_all {|user| user.n_uninvoiced_shipments > 0}
  end
  
  def identify_economic_id
    invoice = Invoice.find params[:id]
    match(Economic.identify_booked_invoice invoice) do
      with(_[:error, issue]) do
        flash[:error] = issue
      end
      with(res) do
      end
    end
    redirect_to :back
  end
  
end
