class AddressesController < ApplicationController
  before_filter :authenticate_user
  
  def index
    @addresses = @current_user.addresses.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end
  
  def new
    @address = Address.new
  end
  
  def edit
    @address = Address.find params[:id]
  end
  
  def create
    address = Address.new address_params
    address.save
    
    record = AddressBookRecord.new
    record.user = @current_user
    record.address = address
    record.save
    
    
    
    redirect_to :action => 'index'
  end
  
  def update
    address = Address.find params[:id]
    address.update address_params
    address.save
    
    if params[:default_address]
      @current_user.default_address = address
      @current_user.save
    else
      if @current_user.default_address == address
        @current_user.default_address = nil
        @current_user.save
      end
    end
    
    redirect_to :action => 'index'
  end
  
  def send_to
    redirect_to :controller => 'shipments', :action => 'new', :send_to => params[:id]
  end
  
 private
 
  def address_params
    params.require(:address).permit(:company_name, :attention, :address_line1,
                                  :address_line2,:zip_code,
                                  :city, :phone_number,
                                  :email, :country_code)
  end
  
end
