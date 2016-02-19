module SessionsHelper


  def is_logged_in
    return session[:user_id] != nil
  end


end
