Spree::Core::Engine.routes.draw do
  post 'amazon/fps' => 'amazon_fps#fps'
  post 'amazon/ipn' => 'amazon_fps#ipn'
  get 'amazon/complete' => 'amazon_fps#complete'
  get 'amazon/abort' => 'amazon_fps#abort'

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
