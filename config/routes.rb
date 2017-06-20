Rails.application.routes.draw do
  devise_for :users, :controllers => { :registrations => "registrations" }
  root to: 'run#index'
  resources :run do
    get :sales_receipt_report
    get :credits_memo_report
  end
  get '/errors_report/' => 'run#errors', as: :errors_report
end
