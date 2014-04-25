Spree::Core::Engine.routes.draw do
  post 'amazon/fps' => 'amazon#fps'
  get 'amazon/complete' => 'amazon#complete'
end
