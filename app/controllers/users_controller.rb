class UsersController < ApplicationController
  before_filter :authenticate_admin


  def index
    @users = User.all.paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def edit
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
      redirect_to :action => 'index'
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
    @products = Product.all
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
    
    redirect_to :action => :index
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

  private

  def user_params
    params.require(:user).permit(:email,:cargoflux_api_key,
                                   :password,:password_confirmation,
                                   :role,:billing_type,:unit_price)
  end
    
  def address_params
    params.require(:address).permit(:company_name, :attention, :address_line1,
                                  :address_line2,:zip_code,
                                  :city, :phone_number,
                                  :email, :country_code)
  end

end
