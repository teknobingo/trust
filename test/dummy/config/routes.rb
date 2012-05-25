Dummy::Application.routes.draw do
  resources :clients

  resources :users
    
  resources :client do
    resources :savings_accounts, :shallow => true
    resources :accounts
    namespace :accounts do
      resources :credit, :shallow => true
    end
  end

end
