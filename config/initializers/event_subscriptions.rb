

ActiveSupport::Notifications.subscribe('preload') do  |name, start, finish, id, payload|
  if not payload[:user].verify_epay_subscription and not (payload[:controller].controller_name == 'account' and payload[:controller].action_name == 'epay_subscribe') 
    payload[:controller].redirect_to controller: 'account', action: 'epay_subscribe'
  end
end