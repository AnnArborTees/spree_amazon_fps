require 'net/http'

module Spree
  class AmazonController < StoreController
    def fps
      order = current_order
      raise(ActiveRecord::RecordNotFound) unless order

      item_names = order.line_items.map { |item| item.product.name + " x#{item.quantity}: " + item.display_total.to_s }

      test_render_str = 'names: '
      test_render_str << item_names.join(', ')

      test_render_str << "<br />adjustments: "
      test_render_str << order.adjustments.all.map { |a| a.label }.join(', ')

      test_render_str << "<br />total cost: " << order.display_total.to_s

      @amazon_params = {
        accessKey:   payment_method.get(:access_key),
        amount:      order.total,
        description: item_names.join('; '),
        # referenceId: "order#{order.id}",

        signatureMethod:  'HmacSHA256',
        signatureVersion: '2',

        returnUrl: full_url_for(controller: 'amazon',
                                action: 'complete'),
        abandonUrl: full_url_for(controller: 'amazon',
                                 action: 'abort'),
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

      # render inline: test_render_str
    end

    def complete
      order = current_order
      raise(ActiveRecord::RecordNotFound) unless order

      rend = ''
      redirect_to '404.html' unless verify_signature

      
      order.payments.create!({
        source: Spree::AmazonCheckout.create({
          reference_id: params[:referenceId],
          status:       params[:status],
        }),
        amount: order.total,
        payment_method: payment_method
      })
      order.next
      if order.complete?
        rend << "COMPLETE<br />"
      else
        rend << "NOOOOOOOO<br />"
      end
      

      rend << "<br /><br /><a href='/checkout/delivery'>Back to checkout</a>"

      render text: rend
    end

    def abort
      rend = 'oh nooooooooo (aborted)<br />'
      rend << "<a href='/checkout/delivery'>Back to checkout</a>"
      render text: rend
    end

  private
    def payment_method
      Spree::PaymentMethod.where(type: 'Spree::Gateway::AmazonFps').first
    end

    def full_url_for(options)
      url_for(options.merge({host: request.env['SERVER_NAME']}))
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