Spree::Core::Engine.routes.draw do
  post '/mollie/notify', to: 'mollie#notify', as: 'notify_mollie'
  get 'mollie/check_status/:order_id', to: 'mollie#check_payment_status', as: 'mollie_check_status'
  get 'mollie/get_payment/:transaction_id', to: 'mollie#get_payment', as: 'mollie_get_payment', defaults: { format: :js }

  namespace :admin do
    resources :orders, :only => [] do
      resources :payments, :only => [] do
        member do
          get 'mollie_refund'
        end
      end
    end
  end
end