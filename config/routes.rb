Rails.application.routes.draw do

  resources :users do
    member do
      post :add_product
      post :set_product_alias
      post :remove_product
      get :edit_products
      get :edit_contact_address
      
      patch :update_contact_address
      resources :products, only: [] do
        get :edit_price_scheme
        patch :update_price_scheme
        patch :default_price_scheme
      end
      
      get :shipments
    end
  end

  resources :products do
    member do
      get :edit_cost
      patch :update_cost_scheme
      get :edit_default_price
      patch :update_default_price_scheme
    end
  end

  resources :shipments do
    member do
      post :submit
      post :callback
      post :reprint
      post :email
      get :copy
    end
  end
  
  resources :invoices, only: [:show] do
    get :shipments
  end
  
  resources :addresses do
    member do
      get :send_to
      get :json
    end
  end
  
  post 'shipments/upload_csv', to: 'shipments#upload_csv'
  get 'bulk_import', to: 'shipments#bulk_import'


  resources :import_formats do
    member do
      get :edit_for_user
    end
  end

  resources :invoices do
  end
  

  #Session handling
  root 'sessions#index'
  post 'login', to: 'sessions#login_attempt'
  get 'home', to: 'sessions#home'
  get 'logout', to: 'sessions#logout'

  #eShip API
  post 'api/products', to: 'api#product_codes'
  post 'api/create_shipment', to: 'api#create_shipment'
  post 'api/fresh_labels', to: 'api#fresh_labels'
  post 'api/recent_failures', to: 'api#recent_failures'
  post 'api/import', to: 'api#upload_csv'
  post 'api/validate_key', to: 'api#validate_key'
  post 'api/shipment_info', to: 'api#shipment_info'
  post 'api/client_version', to: 'api#client_version'
  post 'api/pn/servicepoints', to: 'api#pn_servicepoint_by_address'


  #User account
  get 'account', to: 'account#index'
  get 'account/change_password', to: 'account#change_password', as: 'change_password'
  post 'account/do_change_password', to: 'account#do_change_password', as: 'do_change_password'
  get 'account/products', to: 'account#products', as: 'my_products'
  get 'account/invoices', to: 'account#invoices', as: 'my_invoices'
  get 'account/invoices/:id', to: 'account#invoices_show', as: 'my_invoices_show'
  get 'account/invoices/:id/shipments', to: 'account#invoices_shipments', as: 'my_invoices_shipments'

  #Billing
  get 'billing/user/:id', to: 'billing#user', as: 'user_billing'
  get 'billing/user/:id/edit_prices', to: 'billing#edit_prices', as: 'user_edit_prices'
  post 'billing/invoice', to: 'billing#invoice', as: 'invoice_all'
  post 'billing/user/:id/update_prices', to: 'billing#update_prices', as: 'user_update_prices'
  post 'billing/invoice/:id/submit', to:'billing#submit_invoice', as: 'submit_invoice'


  #Admin
  get 'admin/dashboard', to: 'admin#dashboard', as: 'admin_dashboard'
  get 'admin/shipment/:id', to: 'admin#show_shipment', as: 'admin_shipment'
  get 'admin/tools', to: 'admin#tools', as: 'admin_tools'
  post 'admin/tools/verify_billable_shipments', to: 'admin#verify_billable_shipments', as: 'admin_verify_billable'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
