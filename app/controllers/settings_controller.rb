class SettingsController < ApplicationController
  before_filter :authenticate_user
  
  
  
  def index
    @settings = @current_user.settings
  end
  
  def update
    settings = @current_user.settings # Always user's own settings regardless of get value
    settings.update settings_params
    
    default_countries.each do |product_code, country|
      product = current_user.products.where('product_code LIKE ?', product_code).first
      user_product = current_user.user_products.where('product_id LIKE ?', product.id).first
      user_product.default_country = country
      user_product.save
    end
    
    redirect_to settings_path
  end
  
  def settings_set key, value
    
  end

private

  def settings_params
    params.require(:user_setting).permit(:package_length, :package_width, :package_height, :package_weight)
  end  
  
  def default_countries
    params.require(:default_country)
  end

end