class LabelMailer < ApplicationMailer

  def label_email shipment
    @email_shipment = shipment
    mail(to: shipment.recipient.email, subject: 'Label for shipment ' + shipment.awb)
  end
  
end