class ApplicationMailer < ActionMailer::Base
  default from: "eShip <no-reply@eship.dk>"
  layout 'mailer'
end