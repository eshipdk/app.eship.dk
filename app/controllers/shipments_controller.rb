class ShipmentsController < ApplicationController
  before_filter :authenticate_user, :except => ['callback']
  skip_before_action :verify_authenticity_token, :only => ['callback']

  def index
    #@shipments = @current_user.shipments.order(id: :desc)
    @shipments = @current_user.shipments.order(id: :desc).paginate(:page => params[:page], :per_page => 5)
  end

  def show
    @shipment = Shipment.find(params[:id])
  end

  def new
    @shipment = Shipment.new
    @shipment.user = @current_user
  end

  def edit
    @shipment = Shipment.find(params[:id])
    if !@shipment.can_edit
      redirect_to '/'
    end
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
      @shipment.submit
      redirect_to :action => 'index'
    else
      render 'new'
    end
  end
  
  def bulk_import

  end

  def upload_csv
    uploaded_file = params[:file]
    file_content = uploaded_file.read
    res = Shipment.import_csv file_content, @current_user

    if res['error']
      flash[:error] = res['msg']
    end
    redirect_to :action => 'index'
  end

  def update
    shipment = Shipment.find(params[:id])
    shipment.update(shipment_params)
    shipment.sender.update(address_params(:sender))
    shipment.recipient.update(address_params(:recipient))


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
    response = shipment.submit
    #render :text => "Response #{response}. Shipment status: #{shipment.status}"
    redirect_to :action => 'show'
  end


  def callback
    shipment = Shipment.find(params[:id])

    if params['status'] == 'booked'
      shipment.status = 'complete'
      shipment.awb = params['awb']
      shipment.document_url = params['awb_asset_url']
    else
      shipment.status = 'failed'
    end

    shipment.api_response = params.to_json
    shipment.register_label_pending

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

  private

  def shipment_params
    params.require(:shipment).permit(:product_id, :return,
                                     :package_length, :package_width,
                                     :package_height, :package_weight,
                                     :description, :amount, :reference,
                                     :parcelshop_id)
  end

  def address_params(prefix)
    params.require(prefix).permit(:company_name, :attention, :address_line1,
                                  :address_line2,:zip_code,
                                  :city, :phone_number,
                                  :email, :country_code)
  end

end
