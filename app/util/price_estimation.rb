
module PriceEstimation


def estimate_price user, product, packages, country_from, country_to
      
  shipment = Shipment.new
  shipment.product = product
  shipment.packages = packages
  shipment.user = user
  
  
  sender = Address.new
  sender.country_code = country_from
  shipment.sender = sender
  
  recipient = Address.new
  recipient.country_code = country_to
  shipment.recipient = recipient
     
  price, issue = shipment.calculate_price false
  diesel_fee = shipment.calculate_diesel_fee
  return price + diesel_fee, issue
end

end