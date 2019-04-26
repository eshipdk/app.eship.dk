# Shipment form helper
module ShipmentsHelper
  def form_address_new(type)
    return @current_user.default_address if type == 'sender' &&
                                            @current_user.default_address

    if type == 'recipient' && params[:send_to]
      address = Address.find params[:send_to]
      return address if @current_user.addresses_include? address
    end
    Address.new
  end

  def form_address_edit(shipment, type)
    return shipment.sender if type == 'sender'
    return shipment.recipient if type == 'recipient'
  end

  def form_address(shipment, type)
    if shipment.new_record? && !@cloning
      form_address_new(type)
    else
      form_address_edit(shipment, type)
    end
  end
end
