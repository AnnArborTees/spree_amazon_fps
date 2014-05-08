require 'net/http'

module Spree
  class AmazonController < StoreController
    def fps
      order = current_order
      raise(ActiveRecord::RecordNotFound) unless order

      item_names = order.line_items.map { |item| item.product.name + " x#{item.quantity}: " + item.display_total.to_s }
      item_names << "Shipping: #{order.display_shipment_total}"

      item_names_str = item_names.join ' | '
      # TODO do a better job at truncation
      item_names_str = item_names_str[0..96]+'...' if item_names_str.length > 100
      @amazon_params = {
        accessKey:   payment_method.get(:access_key),
        amount:      order.total,
        description: item_names_str,

        signatureMethod:  'HmacSHA256',
        signatureVersion: '2',

        returnUrl:  full_url_for(action: 'complete'),
        abandonUrl: full_url_for(action: 'abort'),
        ipnUrl:     full_url_for(action: 'ipn'),

        processImmediate: '0',

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

      @end_point = payment_method.end_point_url_str
    end

    def complete
      order = current_order
      raise(ActiveRecord::RecordNotFound) unless order
      
      unless payment_method
        flash[:error] = params[:errorMessage]
        redirect_to checkout_state_path(order.state) unless payment_method
        return
      end

      raise ActionController::RoutingError.new('Invalid Amazon signature') unless verify_signature

      checkout = Spree::AmazonCheckout.find params[:referenceId]
      checkout.update_attributes(transaction_id: params[:transactionId])

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
        flash[:error] = 'Amazon payment failed. You have not been charged.'
        redirect_to checkout_state_path(order.state)
      end
    end

    def abort
      if current_order
        redirect_to checkout_state_path(current_order)
      else
        redirect_to checkout_path
      end
    end

    def ipn
      # Testing this will require an open port
      puts '@@@@@@@@@@@@!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!@@@@@@@@@@@@@!!!!!!!!!!!!'
      puts '@@@@@@@@@@@@!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!@@@@@@@@@@@@@!!!!!!!!!!!!'
      puts '@@@@@@@@@@@@!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!@@@@@@@@@@@@@!!!!!!!!!!!!'
      puts 'WHOA IPN'
      puts '@@@@@@@@@@@@!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!@@@@@@@@@@@@@!!!!!!!!!!!!'
      puts '@@@@@@@@@@@@!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!@@@@@@@@@@@@@!!!!!!!!!!!!'
      File::open("#{Rails.root}/IPN_OMG.txt", "w+") do |f| 
        f << "HERE IT IS.\n"
        f << "the ipn\n"
        f << "it's real...."
      end
    end

  private
    def payment_method
      if params[:payment_method_id]
        Spree::PaymentMethod.find(params[:payment_method_id])
      elsif params[:referenceId]
        Spree::AmazonCheckout.find(params[:referenceId]).payment_method
      elsif params[:errorMessage]
        nil
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