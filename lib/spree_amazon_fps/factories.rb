FactoryGirl.define do
	factory :amazon_payment, class: Spree::Gateway::AmazonFps do
		name 'Amazon'
		type 'Spree::Gateway::AmazonFps'
		description 'Test Amazon Gateway'
		active 1
		environment :test
	end
end
