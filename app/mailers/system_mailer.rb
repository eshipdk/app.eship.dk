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
  
  def ftp_upload_import_failed filename, issue
    @issue = issue
    mail(to: EShip::WEBMASTER_MAIL, subject: "Failed importing #{filename} from ftp uploads..")
  end
  
  def send_reset_password_link user    
    @user = user
    mail(to: user.email, subject: "Reset password to eship.dk")
  end
  
end