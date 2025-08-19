Rails.application.routes.draw do
  # Consultation routes
  resources :consultations, only: [ :new, :create, :show ]
  root "home#index"

  get "conditions/index"
  get "test1/test1"
  get "top" => "home#top"
  get "search" => "home#search"

  get "about" => "home#about"


  get "degreeseeking" => "home#degreeseeking"

  get "info" => "home#info"

  get "recruit" => "home#recruit"

  get "contact" => "home#contact"
  post "contact" => "home#send_contact"

  # Survey routes
  post "surveys" => "surveys#create"

  # Admin authentication routes
  get "admin/login" => "admin/sessions#new", as: :admin_login
  post "admin/login" => "admin/sessions#create"
  delete "admin/logout" => "admin/sessions#destroy", as: :admin_logout

  # Admin setup routes
  get "admin/setup" => "admin/setup#show", as: :admin_setup
  post "admin/setup" => "admin/setup#create"

  # Admin dashboard
  get "admin" => "admin/dashboard#index", as: :admin_dashboard
  get "admin/dashboard" => "admin/dashboard#index"

  # Admin management routes
  namespace :admin do
    resources :consultations, only: [ :index, :show, :update, :destroy ] do
      member do
        patch :confirm
        patch :cancel
        patch :complete
      end
    end
    resources :users, only: [ :index, :show, :destroy ]
    resources :conditions, only: [ :index, :show, :edit, :update, :destroy ]
    resources :surveys, only: [ :index, :show, :destroy ] do
      collection do
        delete :destroy_all
        get :export_csv
      end
    end
  end

  get "terms" => "home#terms"

  # Authentication routes
  get "login" => "sessions#new"
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy"

  # Password reset routes
  resources :password_resets, only: [ :new, :create, :show, :update ]

  # User registration routes
  get "register" => "users#new"
  post "register" => "users#create"
  post "check_username" => "users#check_username"

  # ユーザープロフィール関連
  get "/profile", to: "users#show"
  get "/profile/edit", to: "users#edit"
  patch "/profile", to: "users#update"
  delete "/profile", to: "users#destroy"

  # お気に入り関連
  get "/favorites", to: "favorites#index"
  post "/favorites", to: "favorites#create"
  delete "/favorites", to: "favorites#destroy"

  # 比較機能関連
  get "/compare", to: "comparisons#index"
  post "/compare", to: "comparisons#create"
  delete "/compare", to: "comparisons#destroy"
  delete "/compare/clear", to: "comparisons#clear"

  get "/results", to: "conditions#results"

  # 州別ガイドページ
  get "/states", to: "states#index"
  get "/states/:state_code", to: "states#show", as: "state_detail"

  get "canada" => "home#canada"

  get "australia" => "home#australia"

  get "newzealand" => "home#newzealand"

  get "study_abroad_types" => "home#study_abroad_types"
  get "scholarships" => "home#scholarships"
  get "visa_guide" => "home#visa_guide"
  get "english_tests" => "home#english_tests"
  get "majors_careers" => "home#majors_careers"
  get "life_guide" => "home#life_guide"
  get "why_study_abroad" => "home#why_study_abroad"

  # Blog routes
  get "/blogs", to: "blogs#index", as: :blogs
  get "/blogs/:slug", to: "blogs#show", as: :blog

  # Column routes
  get "/columns", to: "columns#index", as: :columns

  namespace :admin do
    resources :blogs do
      collection do
        get :load_template
      end
    end
  end

  # Dynamic pages (新しい記事はここ)
  get "/p/:page", to: "pages#show", as: :page

  get "/import_conditions", to: "import#conditions"

  # USA routes
  namespace :us do
    get "/", to: "home#index", as: :home
    get "/about", to: "universities#about", as: :about
    resources :universities, only: [ :index, :show ] do
      collection do
        get :search
      end
    end
  end

  # Australia routes
  namespace :au do
    get "/", to: "home#index", as: :home
    get "/about", to: "universities#about", as: :about
    resources :universities, only: [ :index, :show ] do
      collection do
        get :search
      end
    end
  end

  # New Zealand routes
  namespace :nz do
    get "/", to: "home#index", as: :home
    get "/about", to: "universities#about", as: :about
    resources :universities, only: [ :index, :show ] do
      collection do
        get :search
      end
    end
  end

  # Canada routes
  namespace :ca do
    get "/", to: "home#index", as: :home
    get "/about", to: "universities#about", as: :about
    resources :universities, only: [ :index, :show ] do
      collection do
        get :search
      end
    end
  end


  # get 'college_about/:college_name', to: 'conditions#show', as: 'college_detail'
  # get '/:college_name', to: 'conditions#show', as: 'college_detail'


  get "/ohio_northern_university", to: "conditions#ohio_northern_university"
  get "/ohio_state_university", to: "conditions#ohio_state_university"
  get "/florida_state_university", to: "conditions#florida_state_university"
  get "/alabama_state_university", to: "conditions#alabama_state_university"

  # どのルートにもマッチしない場合、fallback_page アクションを呼び出す


  get "debug/db_status", to: "debug#db_status"
  get "debug/manual_import", to: "debug#manual_import"

  # 旧セットアップルート（削除済み）

  get "result/:id", to: "conditions#show", as: :conditions
  get "*unmatched_route", to: "conditions#fallback_page"










  # Set 'college_about/:college_name', to: 'college_about#show', as: 'college_detail'


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
