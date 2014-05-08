class Spree::AmazonFpsCheckout < ActiveRecord::Base
	def payment_method
		Spree::PaymentMethod.find payment_method_id
	end
end
