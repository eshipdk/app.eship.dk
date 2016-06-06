include Cargoflux
include CsvImporter
class ShipmentsController < ApplicationController
  before_filter :authenticate_user, :except => ['callback']
  skip_before_action :verify_authenticity_token, :only => ['callback']
  before_filter :filter_dates, :only => :index

  def index
    #@shipments = @current_user.shipments.order(id: :desc)
    
    @shipments = @current_user.shipments.where('shipments.created_at > ?', @dateFrom).where('shipments.created_at < ?', @dateTo)
    if params[:id]
       @shipments = @shipments.filter_pretty_id(params[:id]) 
    end
    if params[:reference] != nil and params[:reference] != ''
      @shipments = @shipments.where('reference LIKE ?', "%#{params[:reference]}%")
    end
    if params[:recipient] != nil and params[:recipient] != ''
      @shipments = @shipments.filter_recipient_name(params['recipient'])
    end
    @shipments = @shipments.order(id: :desc).paginate(:page => params[:page], :per_page => DEFAULT_PER_PAGE)
  end

  def show
    @shipment = Shipment.find params[:id]
    if @shipment.user != @current_user
      redirect_to :action => :index
    end
    
    @shipment.update_shipping_state
  end

  def new
    @shipment = Shipment.new
    if params[:copy]
      @old_shipment = Shipment.find(params[:copy])
      if @old_shipment.user != @current_user
        redirect_to '/'
        return
      end
      @shipment = Shipment.new @old_shipment.attributes
      @shipment.id = nil
      @cloning = true
      packages = []
      @old_shipment.packages.each do |package|
        packages.append Package.new package.attributes
      end
      @shipment.packages = packages
    else
      @shipment.packages.build
      @shipment.user = @current_user
    end
  end

  def edit
    @shipment = Shipment.find(params[:id])
    if !@shipment.can_edit or @shipment.user != @current_user
      redirect_to '/'
    end
  end

  def copy
    @shipment = Shipment.find(params[:id])
    if @shipment.user != @current_user
      redirect_to '/'
      return
    end

    redirect_to :controller => :shipments, :action => :new, :copy => params[:id]
  end

  def create
    @shipment = Shipment.new(shipment_params)

    sender = Address.new(address_params(:sender))
    recipient = Address.new(address_params(:recipient))

    if !sender.valid? || !recipient.valid?
      render 'new'
      return
    end


    sender.save
    recipient.save

    @shipment.sender_address_id = sender.id
    @shipment.recipient_address_id = recipient.id
    @shipment.user_id = @current_user.id
    
    

    if @shipment.save
      Cargoflux.submit @shipment
      redirect_to :action => 'index'
    else
      render 'new'
    end
  end
  
  def destroy
    @shipment = Shipment.find(params[:id])
    @shipment.destroy

    redirect_to :action => 'index'
  end
  
  def bulk_import

  end

  def upload_csv
    uploaded_file = params[:file]
    file_content = uploaded_file.read
    res = CsvImporter.import_csv file_content, @current_user

    if res['error']
      flash[:error] = res['msg']
    end
    redirect_to :action => 'index'
  end

  def update
    shipment = Shipment.find(params[:id])
    
    if not shipment.can_edit or shipment.user != @current_user
      redirect_to :action => :index
      return
    end

    packages_attributes = shipment_params['packages_attributes'].clone
    for i in 0.. shipment.packages.length - 1
      if packages_attributes[i.to_s].length == 1
        shipment.packages[i].mark_for_destruction
      end
    end

    shipment.update(shipment_params)
    shipment.sender.update(address_params(:sender))
    shipment.recipient.update(address_params(:recipient))
    
    Cargoflux.submit shipment

    redirect_to :action => 'show'
  end

  def submit
    shipment = Shipment.find(params[:id])
    if !shipment.can_submit || shipment.user != @current_user
      redirect_to '/'
      return
    end


  #  render :text => shipment.request_data.to_json
  #  return
    response = Cargoflux.submit shipment
    #render :text => "Response #{response}. Shipment status: #{shipment.status}"
    redirect_to :action => 'show'
  end


  def callback
    shipment = Shipment.find(params[:id])

    if params['status'] == 'booked'
      shipment.status = 'complete'
      shipment.shipping_state = 'booked'
      shipment.awb = params['awb']
      shipment.document_url = params['awb_asset_url']
    else
      shipment.status = 'failed'
    end

    shipment.api_response = params.to_json
    if shipment.label_action == 'print' || shipment.status != 'complete'
      logger.debug 'Autoprint'
      shipment.register_label_pending
    elsif shipment.label_action == 'email'
      logger.debug 'Send email'
      LabelMailer.label_email(shipment).deliver_now
    end
    
    shipment.save
    redirect_to '/'
  end

  def reprint
    shipment = Shipment.find(params[:id])

    if !shipment.status == :complete && !shipment.status == :failed
      flash[:error] = "Invalid shipment status"
    else
      shipment.register_label_pending
      shipment.save
    end
    redirect_to :action => 'show'
  end
  
  def email
    shipment = Shipment.find(params[:id])
    
    if shipment.can_print
      LabelMailer.label_email(shipment).deliver_now
    end
    
    redirect_to :action => 'show'
  end

  private

  def shipment_params
    params.require(:shipment).permit(:product_id, :return,
                                     :package_length, :package_width,
                                     :package_height, :package_weight,
                                     :description, :amount, :reference,
                                     :parcelshop_id, :label_action, :remarks, :delivery_instructions).merge(
          {'packages_attributes' => params.require(:shipment).require(:packages_attributes)})
  end

  def address_params(prefix)
    params.require(prefix).permit(:company_name, :attention, :address_line1,
                                  :address_line2,:zip_code,
                                  :city, :phone_number,
                                  :email, :country_code)
  end

end
