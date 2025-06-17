Rails.application.routes.draw do
  root "home#top"

  get "conditions/index"
  get "test1/test1"
  get "top" => "home#top"

  get "about" => "home#about"

  get "knowledge" => "home#knowledge"

  get "degreeseeking" => "home#degreeseeking"

  get "info" => "home#info"

  get "recruit" => "home#recruit"

  get "contact" => "home#contact"

  get '/results', to: 'conditions#results'

  get "canada" => "home#canada"

  get "australia" => "home#australia"

  get "newzealand" => "home#newzealand"

  get '/import_conditions', to: 'import#conditions'


  #get 'college_about/:college_name', to: 'conditions#show', as: 'college_detail'
  #get '/:college_name', to: 'conditions#show', as: 'college_detail'


  get '/ohio_northern_university', to: 'conditions#ohio_northern_university'
  get '/ohio_state_university', to: 'conditions#ohio_state_university'
  get '/florida_state_university', to: 'conditions#florida_state_university'
  get '/alabama_state_university', to: 'conditions#alabama_state_university'

  # どのルートにもマッチしない場合、fallback_page アクションを呼び出す
  
  
  get 'debug/db_status', to: 'debug#db_status'

  get 'result/:id', to: 'conditions#show', as: :conditions
  get '*unmatched_route', to: 'conditions#fallback_page'
 
  








  #Set 'college_about/:college_name', to: 'college_about#show', as: 'college_detail'


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





