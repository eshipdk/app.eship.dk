Rails.application.routes.draw do

  resources :users do
    member do
      post :add_product
      post :remove_product
      get :edit_products
      get :edit_contact_address
      patch :update_contact_address
    end
  end

  resources :products

  resources :shipments do
    member do
      post :submit
      post :callback
      post :reprint
    end
  end
  
  resources :addresses do
    member do
      get :send_to
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


  #User account
  get 'account', to: 'account#index'

  #Billing
  get 'billing/user/:id', to: 'billing#user', as: 'user_billing'
  post 'billing/invoice', to: 'billing#invoice', as: 'invoice_all'

  #Admin dashboard
  get 'admin/dashboard', to: 'admin#dashboard', as: 'admin_dashboard'

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
