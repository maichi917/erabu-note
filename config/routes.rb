Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: "users/registrations" }
  devise_scope :user do
    post "users/guest_sign_in", to: "users/sessions#guest_sign_in", as: :guest_sign_in
  end
  delete "account/line", to: "users/line_connections#destroy", as: :disconnect_line
  root "static_pages#top"
  get "guide", to: "static_pages#guide", as: :guide
  get "terms", to: "static_pages#terms", as: :terms
  get "privacy", to: "static_pages#privacy", as: :privacy
  get "contact", to: "static_pages#contact", as: :contact

  resources :items, only: %i[index new create show edit update destroy] do
    member do
      patch :start_using
      patch :finish_using
      patch :add_stock
      patch :toggle_favorite
      delete :image, action: :destroy_image
    end

    collection do
      get :used_up
      get :in_use
      get :autocomplete
    end
  end

  resources :usage_logs, only: %i[show edit update] do
    collection do
      get :reviews
    end
  end
end
