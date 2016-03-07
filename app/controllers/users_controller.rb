class UsersController < ApplicationController
  before_filter :authenticate_admin


  def index
    @users = User.all.paginate(:page => params[:page], :per_page => 5)
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

    if @user.save
      redirect_to :action => 'index'
    else
      render 'new'
    end
  end



  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
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

    private

    def user_params
      params.require(:user).permit(:email,:cargoflux_api_key,
                                   :password,:password_confirmation,
                                   :role)
    end

end
