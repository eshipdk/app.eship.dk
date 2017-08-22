
class AffiliateController < ApplicationController
  before_filter :authenticate_affiliate
  
  def dashboard
    @affiliate_user = @current_user
  end
  
  
end