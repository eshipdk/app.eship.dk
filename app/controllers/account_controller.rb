class AccountController < ApplicationController
  before_filter :authenticate_user
  before_filter :filter_dates, :only => :invoices
  
  def index
    
  end
  
  def change_password
    
  end
  
  def do_change_password
    if @current_user.update params.require(:user).permit(:password,:password_confirmation)
      redirect_to :action => :index
    else
      render :change_password
    end
  end
  
  def products
    register_products
    @settings = true
  end
  
  def invoices
    @invoices = @current_user.invoices
                  .where(['invoices.created_at > ? AND invoices.created_at < ?',
                          @dateFrom, @dateTo])
                  .where('economic_id IS NOT NULL')
    if params[:id] and params[:id].to_i > 0
       @invoices = @invoices.where('id = ?', params[:id]) 
    end
    @invoices = @invoices.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end
  
  def invoices_show
    @invoice = Invoice.find params[:id]
    if @invoice.user != @current_user
      redirect_to home_path
    else
      render 'invoices/show'
    end
  end
  
  def invoices_shipments
    @invoice = Invoice.find params[:id]
    if @invoice.user != @current_user
      redirect_to home_path
    else
      @shipments = @invoice.shipments
      render 'invoices/shipments'
    end
  end
  
  def epay_subscribe
    if not @current_user.epay?
      redirect_to '/account'
      return
    end
    @callback_url =  EShip::HOST_ADDRESS + "users/#{@current_user.id}/epay_subscribe"
    @accept_url = EShip::HOST_ADDRESS + "account"

    register_products
    @settings = false
  end
  
  def epay_delete_subscription
    @current_user.epay_subscription_id = nil
    @current_user.save
    redirect_to :back
  end
  
  def update_product
    user_product = UserProduct.find params[:id]
    if user_product.user == current_user
      user_product.update product_settings_params
      user_product.save
    end
    redirect_to my_products_path
  end
  
  def invoice_download
    invoice = Invoice.find params[:id]
    if invoice.user != @current_user and not @current_user.admin?
      redirect_to home_path
    else
      pdf = Economic.get_pdf_data invoice
      send_data pdf, filename: "#{invoice.economic_id}.pdf"
    end
  end
  
private
  def product_settings_params
    params.require(:user_product).permit(:default_length, :default_width, :default_height, :default_weight, :default_country)
  end

  def register_products
    product_groups = @current_user.products
    @products = {}
    @user = @current_user
    product_groups.each do |product|
      product_hash = {:product => product}
      country_products = {}
      price_scheme = product.price_scheme @current_user
      countries = price_scheme.available_countries
      countries.each do |country|
        country_products[country] = price_scheme.product_rows country
      end
      product_hash[:countries] = countries
      product_hash[:country_products] = country_products
      @products[product.product_code] = product_hash
    end
  end
end
