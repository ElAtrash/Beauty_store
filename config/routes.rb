Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "/offline", to: "pages#offline"

  post "/set_locale", to: "locale#set"

  root "home#index"

  # Product routes
  resources :products, only: [ :show ] do
    member do
      patch :update_variant
      get :cart_controls
    end
  end
  resources :categories, only: [ :index, :show ] do
    resources :products, only: [ :index ]
  end
  resources :brands, only: [ :index, :show ] do
    resources :products, only: [ :index ]
  end

  # Cart routes
  resource :cart, only: [ :show, :destroy ] do
    collection do
      get :summary
    end
  end
  resources :cart_items, only: [ :create, :update, :destroy ], path: "cart/items" do
    collection do
      delete :clear_all
    end
  end

  # Checkout routes
  get "checkout", to: "checkout#new", as: :new_checkout
  post "checkout", to: "checkout#create", as: :checkout
  patch "checkout", to: "checkout#update", as: :update_checkout
  get "checkout/:id", to: "checkout#show", as: :checkout_confirmation
  post "checkout/:id/reorder", to: "checkout#reorder", as: :reorder_order
  post "checkout/delivery_schedule", to: "checkout#delivery_schedule", as: :checkout_delivery_schedule
  post "checkout/delivery_summary", to: "checkout#delivery_summary", as: :checkout_delivery_summary

  # Checkout address selection routes (Turbo Frame navigation)
  namespace :checkout do
    resource :address_selection, only: [] do
      get :list
      get :new_form
      get "edit_form/:address_id", action: :edit_form, as: :edit_form
    end
  end

  # Authentication routes
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [ :new, :create ]

  get "login" => "sessions#new"
  get "logout" => "sessions#destroy"
  delete "logout" => "sessions#destroy"
  get "register" => "registrations#new"

  # Address management routes
  resources :addresses do
    member do
      patch :set_default
    end
  end
end
