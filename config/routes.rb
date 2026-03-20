Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users

  namespace :admin do
    root "dashboard#index"

    resources :users,   only: [:index, :show, :edit, :update]
    resources :genres
    resources :bookings, only: [:index, :show] do
      member do
        patch :mark_paid
        patch :cancel
      end
    end
    resources :reports,  only: [:index]

    resources :movies do
      resources :showtimes, shallow: true
    end

    # Standalone showtime index (shallow nesting doesn't create this)
    get "showtimes", to: "showtimes#index", as: :showtimes

    resources :cinemas do
      resources :rooms, shallow: true do
        resources :seats, shallow: true do
          collection do
            get  :generate_form
            post :generate
          end
        end
      end
    end
  end

  namespace :staff do
    root "dashboard#index"
    resources :bookings, only: [:index, :new, :create, :show] do
      collection do
        # Step 2 of counter booking flow: seat map for chosen showtime
        get :seats
      end
      member do
        patch :mark_paid
        patch :cancel
      end
    end
  end

  resources :movies, only: [ :index, :show ]

  # ── Booking flow ──────────────────────────────────────────────────
  get  "showtimes/:id/seats",         to: "seat_selections#show",  as: :showtime_seats
  post "showtimes/:showtime_id/bookings", to: "bookings#create",   as: :showtime_bookings
  get   "bookings/:id/confirmation",      to: "bookings#confirmation",      as: :confirmation_booking
  patch "bookings/:id/simulate_payment",  to: "bookings#simulate_payment",  as: :simulate_payment_booking

  namespace :customer do
    resource  :profile,  only: [ :show, :edit, :update ]
    resources :bookings, only: [ :index, :show ]
  end

  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
