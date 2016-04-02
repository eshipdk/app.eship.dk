class AddressesController < ApplicationController
  before_filter :authenticate_user
  
  def index
    @addresses = @current_user.addresses.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end
  
  def new
    @address = Address.new
    @record = AddressBookRecord.new
  end
  
  def edit
    @address = Address.find params[:id]
    @record = AddressBookRecord.find_by_address_id params[:id]
  end
  
  def create
    address = Address.new address_params
    address.save
    
    record = AddressBookRecord.new record_params
    record.user = @current_user
    record.address = address
    record.save
    
    if params[:default_address]
      @current_user.default_address = address
      @current_user.save
    end
    
    redirect_to :action => :index
  end
  
  def update
    
    record = AddressBookRecord.find_by_address_id params[:id]
    if record.user != @current_user
      redirect_to :action => :index
      return
    end
    
    address = record.address
    address.update address_params
    address.save
    
    record.update record_params
    
    
    if params[:default_address]
      @current_user.default_address = address
      @current_user.save
    else
      if @current_user.default_address == address
        @current_user.default_address = nil
        @current_user.save
      end
    end
    
    redirect_to :action => :index
  end
  
  def destroy
    
    record = AddressBookRecord.find_by_address_id params[:id]
    if record.user != @current_user
      redirect_to :action => :index
      return
    end
    
    #Cannot use :dependent => :nullify because the FK is in the user model
    if record.user.default_address == record.address
      record.user.default_address = nil
      record.user.save
    end
    record.destroy
    
    redirect_to :action => :index
  end
  
  def send_to
    redirect_to :controller => :shipments, :action => :new, :send_to => params[:id]
  end
  
  def json
    address = Address.find params[:id]
    if address.address_book_record.user != @current_user
      address = Address.new
    end
    render :text => address.to_json
  end
  
 private
 
  def address_params
    params.require(:address).permit(:company_name, :attention, :address_line1,
                                  :address_line2,:zip_code,
                                  :city, :phone_number,
                                  :email, :country_code)
  end
  
  def record_params
    res = params.permit(:quick_select_sender, :quick_select_recipient)
    res[:quick_select_sender] = res.key?(:quick_select_sender) and res[:quick_select_sender]
    res[:quick_select_recipient] = res.key?(:quick_select_recipient) and res[:quick_select_recipient]
    return res
  end
  
end
