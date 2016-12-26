require 'savon'
module Epay
  
  SUBSCRIPTION_ENDPOINT = 'https://ssl.ditonlinebetalingssystem.dk/remote/subscription.asmx?WSDL'
  PAYMENT_ENDPOINT = 'https://ssl.ditonlinebetalingssystem.dk/remote/payment.asmx?WSDL'
  
  def capture_invoice invoice
    params = {
      'merchantnumber' => EShip::EPAY_MERCHANT_NUMBER,
      'subscriptionid' => invoice.user.epay_subscription_id.to_s,
      'orderid' => invoice.id.to_s,
      'amount' => (invoice.gross_amount * 100).round.to_s,
      'currency' => '208',
      'instantcapture' => '0',
      'fraud' => '0',
      'transactionid' => '-1',
      'pbsresponse' => '-1',
      'epayresponse' => '-1'
    }

    res = Savon.client(wsdl: SUBSCRIPTION_ENDPOINT).call(:authorize, message: params).body
    if res[:authorize_response][:authorize_result]
      transaction_id = res[:authorize_response][:transactionid]
      params['transactionid'] = transaction_id
      res = Savon.client(wsdl: PAYMENT_ENDPOINT).call(:capture, message: params).body
      if res[:capture_response][:capture_result]
        invoice.captured_online = true
        invoice.save
        return res
      else
        return [:error, res]
      end
    else
      return [:error, res]
    end
  end
  
end