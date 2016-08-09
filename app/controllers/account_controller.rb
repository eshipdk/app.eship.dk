class AccountController < ApplicationController
  before_filter :authenticate_user
  
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
    product_groups = @current_user.products
    @products = {}
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