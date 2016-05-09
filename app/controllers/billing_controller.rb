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
      shipment.price = row['price'] == '' ? nil : row['price'].to_f
      shipment.cost = row['cost'] == '' ? nil : row['cost'].to_f
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
