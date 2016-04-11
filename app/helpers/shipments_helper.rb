module ShipmentsHelper
  
  
  def form_address shipment, type
    
    if shipment.new_record? and not @cloning
      if type == 'sender' && @current_user.default_address
        return @current_user.default_address
      else
        if type == 'recipient' && params[:send_to]
          address = Address.find params[:send_to]
          if @current_user.addresses.include? address
            return address
          end
        end
      end
      return Address.new
    else
      if type == 'sender'
        return shipment.sender
      else
        if type == 'recipient'
          return shipment.recipient
        end
      end
    end
    return nil
    
  end
  
end
