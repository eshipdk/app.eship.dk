require 'savon'
module Epay
  
  SUBSCRIPTION_ENDPOINT = 'https://ssl.ditonlinebetalingssystem.dk/remote/subscription.asmx?WSDL'
  PAYMENT_ENDPOINT = 'https://ssl.ditonlinebetalingssystem.dk/remote/payment.asmx?WSDL'
  
  def capture_invoice invoice
    params = {
      'merchantnumber' => EShip::EPAY_MERCHANT_NUMBER,
      'subscriptionid' => invoice.user.epay_subscription_id.to_s,
      'orderid' => invoice.pretty_id,
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
        invoice.paid = true
        invoice.save
        return res
      else
        return [:error, res]
      end
    else
      return [:error, res]
    end
  end
  
  def get_subscription_data user
    params = {
      'merchantnumber' => EShip::EPAY_MERCHANT_NUMBER,
      'subscriptionid' => user.epay_subscription_id.to_s
    }
    res = Savon.client(wsdl: SUBSCRIPTION_ENDPOINT).call(:getsubscriptions, message: params).body
    data = res[:getsubscriptions_response][:subscription_ary]
    if data
      return data[:subscription_information_type]
    else
      return false
    end    
  end
  
  def delete_subscription user
    params = {
      'merchantnumber' => EShip::EPAY_MERCHANT_NUMBER,
      'subscriptionid' => user.epay_subscription_id.to_s
    }
    res = Savon.client(wsdl: SUBSCRIPTION_ENDPOINT).call(:deletesubscription, message: params).body    
    return res[:deletesubscription_response][:deletesubscription_result]
  end
  
end
