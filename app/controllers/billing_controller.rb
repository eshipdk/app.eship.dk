class BillingController < ApplicationController
  before_filter :authenticate_admin
  
  
  def user
    @user = User.find(params[:id])
    @invoices = @user.invoices.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end
  
  def edit_prices
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
  
  def invoice
    user = User.find(params[:user_id])
   # begin
      user.do_invoice
    #rescue Exception => e
      #flash[:error] = e.to_s
  #  end
    redirect_to user_billing_path(user)
  end
  
end
