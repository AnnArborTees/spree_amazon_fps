Spree::Core::Engine.routes.draw do
  post 'amazon/fps' => 'amazon#fps'
  post 'amazon/ipn' => 'amazon#ipn'
  get 'amazon/complete' => 'amazon#complete'
  get 'amazon/abort' => 'amazon#abort'

  namespace :admin do
  	resources :orders, only: [] do
  		resources :payments, only: [] do
  			member do
  				get 'amazon_refund'
  				post 'amazon_refund'
  			end
  		end
  	end
  end
end
