class SettingsController < ApplicationController
  before_filter :authenticate_user
  
  
  
  def index
    @settings = @current_user.settings
  end
  
  def update
    settings = @current_user.settings # Always user's own settings regardless of get value
    settings.update settings_params
    
    
    redirect_to settings_path
  end
  
  def settings_set key, value
    
  end

private

  def settings_params
    params.require(:user_setting).permit(:package_length, :package_width, :package_height, :package_weight)
  end  

end