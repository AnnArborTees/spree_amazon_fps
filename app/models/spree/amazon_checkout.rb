class Spree::AmazonCheckout < ActiveRecord::Base
	def payment_method
		Spree::PaymentMethod.find payment_method_id
	end
end
