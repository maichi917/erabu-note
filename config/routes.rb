Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: "users/registrations" }
  devise_scope :user do
    post "users/guest_sign_in", to: "users/sessions#guest_sign_in", as: :guest_sign_in
  end
  delete "account/line", to: "users/line_connections#destroy", as: :disconnect_line
  get "home", to: "home#show", as: :home
  root "static_pages#top"
  get "terms", to: "static_pages#terms", as: :terms
  get "privacy", to: "static_pages#privacy", as: :privacy
  get "contact", to: "static_pages#contact", as: :contact

  resources :items, only: %i[index new create show edit update destroy] do
    member do
      patch :toggle_low_stock
      patch :toggle_favorite
      get :confirm_archive
      patch :archive
      patch :unarchive
      # updateアクションだとカテゴリが更新されないので、感想の更新専用アクションを作る
      get :edit_review
      patch :update_review
      delete :image, action: :destroy_image
    end

    collection do
      get :autocomplete
      get :reviews
    end
  end
end
