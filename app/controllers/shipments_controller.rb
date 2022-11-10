include Cargoflux
include CsvImporter
include PriceEstimation
include Economic
class ShipmentsController < ApplicationController
  before_filter :authenticate_user, :except => ['callback']
  skip_before_action :verify_authenticity_token, :only => ['callback']
  before_filter :filter_dates, :only => :index

  def index
    @shipments = @current_user.shipments.where(['shipments.created_at > ? AND shipments.created_at < ?', @dateFrom, @dateTo])
    if params[:id]
       @shipments = @shipments.filter_pretty_id(params[:id]) 
    end
    if params[:reference] != nil and params[:reference] != ''
      @shipments = @shipments.where('reference LIKE ?', "%#{params[:reference]}%")
    end
    if params[:recipient] != nil and params[:recipient] != ''
      @shipments = @shipments.filter_recipient_name(params['recipient'])
    end
    if params[:awb] != nil and params[:awb] != ''
      @shipments = @shipments.where('awb LIKE ?', "%#{params[:awb]}%")
    end
    if params[:booking_state] != nil and params[:booking_state] != ''     
      @shipments = @shipments.where(:status => Shipment.statuses[params[:booking_state]])
    end
    if params[:shipping_state] != nil and params[:shipping_state] != ''
      @shipments = @shipments.where(:shipping_state => Shipment.shipping_states[params[:shipping_state]])
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
    if !@shipment.can_edit or not (@shipment.user == @current_user or @current_user.admin?)
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
    
    if params[:save_quick_sender]
      sender_clone = sender.clone
      sender_clone.save
      record = AddressBookRecord.new
      record.user = @current_user
      record.address = sender_clone
      record.quick_select_sender = true
      record.save    
    end
    if params[:save_quick_recipient]
      recipient_clone = recipient.clone
      recipient_clone.save
      record = AddressBookRecord.new
      record.user = @current_user
      record.address = recipient_clone
      record.quick_select_recipient = true
      record.save    
    end

    @shipment.sender_address_id = sender.id
    @shipment.recipient_address_id = recipient.id
    @shipment.user_id = @current_user.id
    

    if @shipment.save
      if @shipment.price_configured?
        Cargoflux.submit @shipment
        if shipment_params['return'] == 'both'
          book_return_shipment @shipment
        end    
        redirect_to :action => 'index'
      else
        @shipment.status = 'failed'
        @shipment.save
        render 'show'
      end
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
    begin
      uploaded_file = params[:file]
      
      fname = uploaded_file.original_filename.downcase
      ext = /\.([a-zA-Z]*)$/.match(fname).to_s
      case ext
      when '.csv'
        file_content = uploaded_file.read
        file_content = CsvImporter.decode_content file_content
      when '.xlsx'
        sheet = Roo::Spreadsheet.open(uploaded_file.tempfile.path)
        file_content = sheet.to_csv(false, @current_user.import_format.delimiter)        
      else
        raise "Unsupported file extension: #{ext}. Supported formats are: .csv and .xlsx"
      end
      
      
     
      
      begin
        res = CsvImporter.import_csv file_content, @current_user
      rescue CsvImportException => e
        res = {'error' => true, 'msg' => e.issue}
      end
    rescue => e
      res = {'error' => true, 'msg' =>  "#{e.message}"}
    end
    if res['error']
      flash[:error] = res['msg']
      redirect_to :action => 'bulk_import'
    else
      redirect_to :action => 'index'
    end
  end

  def update
    shipment = Shipment.find(params[:id])
    
    if not shipment.can_edit or not (shipment.user == @current_user or @current_user.admin?)
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
    
    if shipment.price_configured?
      Cargoflux.submit shipment
      if shipment_params['return'] == 'both'
        book_return_shipment shipment
      end    
    else
      shipment.status = 'failed'
      shipment.save
    end

    @shipment = shipment
    render'show'
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
      # When using dataimport product we must update the package configuration from cargoflux before determining value
      if shipment.product.product_code == 'dataimport'
        shipment.fetch_packages_from_cargoflux
        shipment.reload  
      end

      shipment.cargoflux_shipment_id = params['unique_shipment_id']
      shipment.status = 'complete'
      shipment.shipping_state = 'booked'
      shipment.awb = params['awb']
      shipment.document_url = params['awb_asset_url']
      shipment.track_and_trace_url = params['track_and_trace_url']
      shipment.determine_value
    else
      shipment.status = 'failed'
    end

    shipment.save

    shipment.api_response = params.to_json
    if shipment.label_action == 'print' || shipment.status != 'complete'
      logger.debug 'Autoprint'
      shipment.register_label_pending
    elsif shipment.label_action == 'email'
      #logger.debug 'Send email'
      #LabelMailer.label_email(shipment).deliver_now
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
  
  def calculate_price
    
    packages = []
    params['packages'].each do |pdata|
      p = Package.new
      p.length = pdata['length'].to_i
      p.width = pdata['width'].to_i
      p.height = pdata['height'].to_i
      p.weight = pdata['weight'].to_f           
      p.amount = pdata['amount'].to_i
      packages.push p
    end
       
    product = Product.find params['product_id']
    
    s = Shipment.new
    s.product = product
    s.user = @current_user
    s.sender = Address.new
    s.sender.country_code = params['countryFrom']
    s.recipient = Address.new
    s.recipient.country_code = params['countryTo']
    s.packages = packages
    
    #price, issue = Cargoflux.price_lookup s
    
    price, issue = PriceEstimation.estimate_price @current_user, product, packages, params['countryFrom'], params['countryTo']   
    response = {:price => price, :issue => issue}
    render :text => response.to_json, :content_type => 'application/json'
  end
  

  private

  def shipment_params
    params.require(:shipment).permit(:product_id, :return,
                                     :package_length, :package_width,
                                     :package_height, :package_weight,
                                     :description, :amount, :reference,
                                     :parcelshop_id, :label_action, :remarks, :delivery_instructions, :addons,
                                     :customs_amount, :customs_currency, :customs_code).merge(
          {'packages_attributes' => params.require(:shipment).require(:packages_attributes)})
  end

  def address_params(prefix)
    params.require(prefix).permit(:company_name, :attention, :address_line1,
                                  :address_line2,:zip_code,
                                  :city, :phone_number,
                                  :email, :country_code)
  end

  # Make an identical booking with return service
  # and the addresses reversed
  def book_return_shipment original_shipment
    shipment = original_shipment.dup
    if original_shipment.product.return_product
      shipment.product = original_shipment.product.return_product
    end
    shipment.status = :initiated
    shipment.cargoflux_shipment_id = nil
    # Reverse addresses
    shipment.recipient = original_shipment.sender
    shipment.sender = original_shipment.recipient
    
    shipment.return = true
    
    packages = []
    original_shipment.packages.each do |package|
      packages.append package.dup
    end
    shipment.packages = packages
    
    shipment.save
    if shipment.price_configured?
      Cargoflux.submit shipment
    else
      shipment.status = :failed
      shipment.save
    end
  end

end
