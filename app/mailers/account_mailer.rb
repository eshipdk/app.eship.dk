class AccountMailer < ApplicationMailer
  

  def send_subscription_confirmation_mail user
    @user = user
    mail(to: user.email, subject: 'Your subscription is now active')
  end
  
  def send_subscription_alteration_mail user
    @user = user
    mail(to: user.email, subject: 'Your subscription details have been updated')
  end
  
  def send_subscription_deletion_mail user
    @user = user
    mail(to: user.email, subject: 'Your subscription has ended')
  end
  
  def send_invoice_mail invoice
    @invoice = invoice
    attachments["#{invoice.pretty_id}.pdf"] = {
      mime_type: 'application/pdf',
      content: Economic.get_pdf_data(invoice)
    }
    mail(to: invoice.user.billing_email, subject: "Fakturanr. #{invoice.pretty_id} - #{invoice.created_at.strftime('%d.%m.%y')} - eShip ApS")
  end
end
