class BillingController < ApplicationController
  before_filter :authenticate_admin
  
  
  def user
    @user = User.find(params[:id])
    @invoices = @user.invoices.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end
  
  def invoice
    user = User.find(params[:user_id])
    user.do_invoice
    redirect_to user_billing_path(user)
  end
  
end
