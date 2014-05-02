Spree::Admin::PaymentsController.class_eval do
	def amazon_refund
		if request.get?
			if @payment.source.status == 'Refunded'
				flash[:error] = 'This payment has already been refunded'
				redirect_to admin_order_payment_path @order, @payment
			end
		elsif request.post?
			response = @payment.payment_method.refund(@payment, params[:refund_amount])
			if !response.error && response.TransactionStatus != 'Cancelled' && response.TransactionStatus != 'Failure'
				flash[:success] = 'Refund Request Sent!'
				redirect_to admin_order_payments_path(@order)
			else
				if(response.error)
					flash.now[:error] = "Refund Failed: #{response.error_message}"
				else
					flash.now[:error] = "Refund Failed"
				end
				render
			end
		end
	end
end