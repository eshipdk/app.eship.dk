include Economic
class UsersController < ApplicationController
  before_filter :authenticate_admin, :except => :epay_subscribe
  before_filter :filter_dates, :only => :shipments

  def index
    @users = User.all.paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
    @users = @users.joins(:contact_address)
    if params[:name]
      @users = @users.where(['users.email LIKE ? or addresses.company_name LIKE ?', "%#{params[:name]}%", "%#{params[:name]}%"])
    end
    if params[:email]
      @users = @users.where(['users.email LIKE ?', "%#{params[:email]}%"])
    end
    if params[:role] and params[:role] != ''
      @users = @users.where(:role => User.roles[params[:role]])
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @economic_customers = Economic.get_customer_options
    @affiliate_users = User.get_affiliate_user_options
    @user = User.new
  end

  def edit
    @economic_customers = Economic.get_customer_options
    @affiliate_users = User.get_affiliate_user_options
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    contact_address = Address.new
    contact_address.save
    @user.contact_address = contact_address
    if @user.save
      @user.contact_address = contact_address
      redirect_to :action => 'index'
    else
      contact_address.destroy
      render 'new'
    end
  end



  def update
    @user = User.find(params[:id])

    params = user_params
    if params[:password] == ''
      params.delete :password
      params.delete :password_confirmation
    end
    if @user.update(params)
      redirect_to user_path(@user)
    else
      render 'edit'
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy

    redirect_to users_path
  end


  def edit_products
    @user = User.find(params[:id])
    @products = Product.where(:disabled => false).order(:name)
  end
  
  def edit_contact_address
    @user = User.find(params[:id])
    @address = @user.contact_address
    if @address == nil
      @address = Address.new
      @address.save
      @user.contact_address = @address
      @user.save
    end
  end

  def update_contact_address
    user = User.find(params[:id])
    address = user.contact_address
    address.update address_params
    address.save
    
    redirect_to user_path(user)
  end

  def add_product
    product = Product.find(params[:product_id])
    user = User.find(params[:id])

    user.add_product(product)
    user.save
    redirect_to :action => :edit_products
  end
  
  def remove_product
    product = Product.find(params[:product_id])
    user = User.find(params[:id])
    
    user.remove_product(product)
    user.save
    redirect_to :action => :edit_products
  end
  
  def set_product_alias
    user = User.find(params[:id])
    link = user.user_products.find_by_product_id(params[:product_id])
    link.alias = params[:alias]
    link.save
    
    redirect_to :action => :edit_products
  end
  
  def shipments
    @user = User.find params[:id]
    @shipments = @user.shipments.where('shipments.created_at > ?', @dateFrom).where('shipments.created_at < ?', @dateTo)
    if params[:shipment_id]
       @shipments = @shipments.filter_pretty_id(params[:shipment_id]) 
    end
    if params[:reference] != nil and params[:reference] != ''
      @shipments = @shipments.where('reference LIKE ?', "%#{params[:reference]}%")
    end
    if params[:recipient] != nil and params[:recipient] != ''
      @shipments = @shipments.filter_recipient_name(params['recipient'])
    end
    if params[:awb] != nil and params[:awb] != ''
      @shipments = @shipments.where('awb LIKE ?', "%#{params[:awb]}%")
    end
    if params[:booking_state] != nil and params[:booking_state] != ''     
      @shipments = @shipments.where(:status => Shipment.statuses[params[:booking_state]])
    end
    if params[:shipping_state] != nil and params[:shipping_state] != ''
      @shipments = @shipments.where(:shipping_state => Shipment.shipping_states[params[:shipping_state]])
    end    
    @shipments = @shipments.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end

  def epay_subscribe
    Rails.logger.warn "EPAY SUBSCRIBE"
    
    user = User.find params[:id]
    if params[:key] != user.eship_api_key
      render :text => 'error'
      return
    end    
    
    if user.epay_subscription_id and not Epay.delete_subscription user
      flash[:error] = 'Failed deleting subscription. Please contact eShip customer service.'
    end
    is_update = user.epay_subscription_id?
    subscription_id = params[:subscriptionid]
    user.epay_subscription_id = subscription_id
    user.save
    
    if is_update
      AccountMailer.send_subscription_alteration_mail(user).deliver_now
    else
      AccountMailer.send_subscription_confirmation_mail(user).deliver_now
    end
    
    render :text => 'ok'
  end
  
  def fetch_address_from_economic
    user = User.find params[:id]
    Economic.update_user_address user
    redirect_to(:back)
  end
  
  def affiliate_dashboard
    @affiliate_user  = User.find params[:id]
    render template: 'affiliate/dashboard'
  end

  private

  def user_params
    p = params.require(:user).permit(:email,:cargoflux_api_key,
                                     :password,:password_confirmation,
                                     :role,:billing_type,:unit_price,
                                     :economic_customer_id, :billing_control,
                                     :invoice_x_days, :invoice_x_balance,
                                     :payment_method, :affiliate_id,
                                     :affiliate_commission_rate,
                                     :affiliate_base_house_amount,
                                     :affiliate_minimum_invoice_amount,
                                     :enable_ftp_upload, :ftp_upload_user,
                                     :invoice_failed_bookings,
                                     :subscription_fee, :monthly_free_labels)
   p[:enable_ftp_upload] = p.key?(:enable_ftp_upload) and p[:enable_ftp_upload]
   p[:invoice_failed_bookings] = p.key?(:invoice_failed_bookings) and p[:invoice_failed_bookings]
   return p
  end
    
  def address_params
    params.require(:address).permit(:company_name, :attention, :address_line1,
                                  :address_line2,:zip_code,
                                  :city, :phone_number,
                                  :email, :country_code)
  end

end
