class ApplicationMailer < ActionMailer::Base
  default from: "postmaster@sandboxaf5ad80c18054824bd892c6f9996da95.mailgun.org"
  layout 'mailer'
end