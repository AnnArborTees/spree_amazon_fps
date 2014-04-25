module Spree
	class AmazonController < StoreController
		def fps
			order = current_order
			raise(ActiveRecord::RecordNotFound) unless order

			item_names = order.line_items.map { |item| item.product.name + ": " + item.display_total.to_s }

			test_render_str = 'names: '
			test_render_str << item_names.join(', ')

			test_render_str << "<br />adjustments: "
			test_render_str << order.adjustments.all.map { |a| a.label }.join(', ')

			test_render_str << "<br />total cost: " << order.display_total.to_s

			amazon_params = {
				accessKey:   payment_method.get(:access_key),
				amount:      order.total,
				description: item_names,
				# referenceId: order.id or something

				signatureMethod:  'HmacSHA256',
				signatureVersion: '2',

				returnUrl: 'http://test.com/amazon/complete',
				abandonUrl: 'peepeeland'
			}
			# TODO PUT PARAMETERS IN HERE:::::::::
			signature = payment_method.sign_params(
				amazon_params, 
				payment_method.get('secret_key'),
				payment_method.end_point_url,
				'POST'
				)
			amazon_params[:signature] = signature

			test_render_str << '<br><br>'
			amazon_params.each_pair do |key, val|  
				test_render_str << key.to_s << ": " << val.to_s
				test_render_str << "<br />"
			end

			# redirect_to payment_method.end_point_url
			render inline: test_render_str
		end

		def complete
			order = current_order
			raise(ActiveRecord::RecordNotFound) unless order

			render inline: 'nice. nice'
		end

	private
		def payment_method
			Spree::PaymentMethod.find params[:payment_method_id]
		end
	end
end