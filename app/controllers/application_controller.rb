class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  DEFAULT_PER_PAGE = 20

  protected
  def authenticate_user
    if session[:user_id]
      # set current user object to @current_user object variable
      @current_user = User.find session[:user_id]
      preload
      return true
    else
      redirect_to '/'
      return false
    end
  end
  def authenticate_admin
    user_authenticated = authenticate_user;
    if user_authenticated  and not @current_user.role=='admin'
      redirect_to home_path
      return false
    else
      if @current_user.role=='admin'
        @admin = true
      end
    end
      return user_authenticated
  end
  def save_login_state
    if session[:user_id]
      redirect_to(:controller => 'sessions', :action => 'home')
      return false
    else
      return true
    end
  end

  def authenticate_api silent = false
    information = request.raw_post
    @api_params = JSON.parse(information)

    @current_user = User.authenticate_api(@api_params['api_key'])
    if @current_user
      return true
    else
      if !silent
        api_error('Invalid/missing API-key', 401)
      end
      return false
    end
  end
  
  

  def api_error(msg, status = 400)
    render :text => {'error' => msg}.to_json, :status => status
  end

  def api_success
    render :text => {'success' => true}.to_json
  end
  
  def filter_dates
    from = params[:from]
    to = params[:to]
    
    if from
      @dateFrom = DateTime.now.change(day: from[:day].to_i, month: from[:month].to_i, year: from[:year].to_i)
      @dateTo = DateTime.now.change(day: to[:day].to_i, month: to[:month].to_i, year: to[:year].to_i)
    elsif session.key?(:filter_date_from)
      @dateFrom = session[:filter_date_from]
      @dateTo = session[:filter_date_to]
    else
      @dateFrom = DateTime.now
      @dateTo = DateTime.now
    end

    @dateFrom = @dateFrom.beginning_of_day
    @dateTo = @dateTo.end_of_day
    
    session[:filter_date_from] = @dateFrom
    session[:filter_date_to] = @dateTo
  end
  
  def preload
    ActiveSupport::Notifications.instrument('preload', user: @current_user, controller: self)
  end
  
 

end
