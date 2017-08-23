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
  
end