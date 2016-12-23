class SystemMailer < ApplicationMailer

  def economic_autosubmit_failed invoice, issue
    @issue = issue
    mail(to: EShip::WEBMASTER_MAIL, subject: "E-conomic submit failed for invoice #{invoice.id} (customer #{invoice.customer.email})")
  end
  
  def epay_autocapture_failed invoice, issue
    @issue = issue
    mail(to: EShip::WEBMASTER_MAIL, subject: "Epay capture failed for invoice #{invoice.id} (customer #{invoice.customer.email})")
  end
  
  def shipment_status_update_failed shipment, issue
    @issue = issue
    mail(to: EShip::WEBMASTER_MAIL, subject: "Shipment status update failed for shipment #{shipment.id} (customer #{shipment.user.email})")
  end
  
end