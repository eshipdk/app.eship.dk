class SessionsController < ApplicationController

  layout 'login'
  before_filter :authenticate_user, :only => [:home]
  before_filter :save_login_state, :only => [:index, :login_attempt]

  def index
    #temporary measure until non-ssl can be removed completely
    if Rails.env == 'production' and request.protocol != 'https://'
      redirect_to 'https://app.eship.dk/'
      return
    end
    render 'login'
  end

  def home
    redirect_to '/shipments'
  end

  def login_attempt
    authorized_user = User.authenticate(params[:email],params[:login_password])
    if authorized_user
      session[:user_id] = authorized_user.id
      flash[:notice] = "Wow Welcome again, you logged in as #{authorized_user.email}"
      redirect_to '/shipments'
    else
      flash[:notice] = "Invalid email or password"
      flash[:color]= "invalid"
      redirect_to '/'
    end
  end

  def logout
    session[:user_id] = nil
    redirect_to '/'
  end




end
