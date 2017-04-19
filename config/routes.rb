Rails.application.routes.draw do
  devise_for :users, :controllers => { :registrations => "registrations" }
  root to: 'run#index'
  get '/errors_report/' => 'run#errors', as: :errors_report
end
