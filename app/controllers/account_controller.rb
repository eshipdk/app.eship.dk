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
  

end