class ApiController < ApplicationController
  before_filter :authenticate_api
  skip_before_filter :verify_authenticity_token




  def product_codes
    products = @current_user.products
    render :text => {'product_codes' => @current_user.products.map(&:product_code)}.to_json
  end


  def create_shipment

    shipment_params = @api_params['shipment']
    if !@current_user.products.map(&:product_code).include? shipment_params['product_code']
      api_error 'Invalid product code: ' + shipment_params['product_code']
      return false
    end

    product = Product.find_by_product_code shipment_params['product_code']

    render :text => product.id
  end


  def fresh_labels

    ready_shipments = @current_user.shipments.where(label_pending: true).where(status: Shipment.statuses[:complete])

    recently_registered = []
    ready_shipments.each do |shipment|
      if shipment.recent_label_pending?
        recently_registered.push shipment
      end
      shipment.label_pending = false
      shipment.save
    end

    render :text => {'labels' => recently_registered.map(&:document_url), 
                      'awbs' => recently_registered.map(&:awb),
                      'ids' => recently_registered.map(&:cargoflux_shipment_id)}.to_json
  end

  def recent_failures

    error_shipments = @current_user.shipments.where(label_pending: true).where(status: Shipment.statuses[:failed])

    response = {}
    shipments = []
    error_shipments.each do |shipment|

      shipment.label_pending = false
      errorShipment = {'id' => shipment.id, 'shipping_id' => shipment.cargoflux_shipment_id, 'errors' => shipment.get_error}
      shipments.push errorShipment

     shipment.save
    end

    render :text => {'shipments'=>shipments}.to_json

  end


  def upload_csv
    csv = @api_params['csv']
    if !csv
      api_error "Missing attribute: csv"
      return
    end

    res = Shipment.import_csv csv, @current_user
    if res['error']
      api_error res['msg']
      return
    end
    api_success
  end

end
