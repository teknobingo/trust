Dummy::Application.routes.draw do
  resources :users

  resources :accounts
    
  resources :client do
    resources :savings_accounts, :shallow => true
    namespace :accounts do
      resources :credit, :shallow => true
    end
  end

end
