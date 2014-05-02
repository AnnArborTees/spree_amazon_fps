require 'net/http'

module Spree
  class AmazonController < StoreController
    def fps
      order = current_order
      raise(ActiveRecord::RecordNotFound) unless order

      item_names = order.line_items.map { |item| item.product.name + " x#{item.quantity}: " + item.display_total.to_s }
      item_names << "Shipping: #{order.display_shipment_total}"

      test_render_str = 'names: '
      test_render_str << item_names.join(', ')

      test_render_str << "<br />adjustments: "
      test_render_str << order.adjustments.all.map { |a| a.label }.join(', ')

      test_render_str << "<br />total cost: " << order.display_total.to_s

      @amazon_params = {
        accessKey:   payment_method.get(:access_key),
        amount:      order.total,
        description: item_names.join(' | '),
        # referenceId: "order#{order.id}",

        signatureMethod:  'HmacSHA256',
        signatureVersion: '2',

        returnUrl:  full_url_for(action: 'complete'),
        abandonUrl: full_url_for(action: 'abort'),
        ipnUrl:     full_url_for(action: 'ipn'),

        referenceId: Spree::AmazonCheckout.create({
                    status: 'Incomplete',
                    payment_method_id: payment_method.id
                  }).id.to_s,

        immediateReturn: '1',
      }

      signature = payment_method.sign_params(
        @amazon_params,
        'POST'
      )
      @amazon_params[:signature] = signature


      test_render_str << '<br /><br />'
      @amazon_params.each_pair do |key, val|  
        test_render_str << key.to_s << ": " << val.to_s
        test_render_str << "<br />"
      end

      puts '*****************************************'
      puts test_render_str.gsub('<br />', "\n")
      puts '*****************************************'

      @end_point = payment_method.end_point_url_str

      render inline: test_render_str
    end

    def complete
      order = current_order
      raise(ActiveRecord::RecordNotFound) unless order

      raise ActionController::RoutingError.new('Invalid Amazon signature') unless verify_signature
      
      checkout = Spree::AmazonCheckout.find params[:referenceId]
      checkout.update_attributes(transaction_id: params[:transactionId])

      # Might have to somehow move this logic into a separate function
      # in case of IPN working
      order.payments.create!({
        source: checkout,
        amount: order.total,
        payment_method: payment_method
      })
      order.next
      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        redirect_to order_path(order, token: order.token)
      else
        # TODO somehow grab a description of the error.
        flash[:error] = 'Amazon payment failed. You have not been charged.'
        redirect_to checkout_state_path(order.state)
      end
    end

    def abort
      rend = 'oh nooooooooo (aborted)<br />'
      rend << "<a href='/checkout/delivery'>Back to checkout</a>"
      render text: rend
    end

    def ipn
      # Testing this will require an open port
      puts '@@@@####$$$$$$%%%%%%%%@@@@@@####$$$%%%%@@@@@####$$%%%'
      puts 'RECEIVED IPN WHOAAAAAAAAAAAAAAA'
      puts 'HERE ARE THE PARAMS'
      puts params.to_s
      puts '@@@@####$$$$$$%%%%%%%%@@@@@@####$$$%%%%@@@@@####$$%%%'
    end

  private
    def payment_method
      if params[:payment_method_id]
        Spree::PaymentMethod.find(params[:payment_method_id])
      elsif params[:referenceId]
        Spree::AmazonCheckout.find(params[:referenceId]).payment_method
      else
        raise ActiveRecord::RecordNotFound.new("There is no PaymentMethod information in the parameters")
      end
    end

    def full_url_for(options)
      url_for({controller: params[:controller]}.merge(options.merge({host: request.env['SERVER_NAME']})))
    end

    def verify_signature
      end_point = full_url_for(controller: params[:controller].to_s,
                               action: params[:action].to_s)
      http_params = params.reject { |k,v| k.to_sym == :controller || k.to_sym == :action }

      resp = payment_method.api.VerifySignature ({ 
              :UrlEndPoint    => end_point, 
              :HttpParameters => http_params.to_query
            })

      return true if resp.VerificationStatus == 'Success'
      false
    end
  end
end