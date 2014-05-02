module Spree
  class Gateway::AmazonFps < Gateway
    preference :access_key, :string
    preference :secret_key, :string
    preference :server, :string, default: 'sandbox'
    preference :logourl, :string, default: ''

    # Begin inner classes for API calls
    class ApiResponse
      def initialize(action, response_xml)
        @action = action
        @doc = Nokogiri::XML(response_xml)
        puts '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
        puts response_xml
        puts '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
      end

      def valid?
        return true if error
        !@doc.css("#{@action}Response").empty?
      end

      def error
        error_code = @doc.css('Response > Errors > Error > Code')
        if error_code.empty?
          return nil
        else
          return error_code.first.content
        end
      end

      def error_message
        @doc.css('Response > Errors > Error > Message').first.content if error
      end

      def respond_to?(name)
        !@doc.css("#{@action}Response > #{@action}Result > #{name}").empty?
      end

      def method_missing(name, *args, &block)
        return nil if error
        super unless respond_to? name
        @doc.css("#{@action}Response > #{@action}Result > #{name}").first.content
      end
    end

    class ApiCall
      def initialize(amazon_gateway)
        @amazon = amazon_gateway
      end

      def respond_to?(name)
        r = call(name, params)
        r.valid? && !r.error
      end

      def call(action, params)
        ApiResponse.new(action, Net::HTTP.get(@amazon.api_call_uri(params)))
      end

      def method_missing(name, *args, &block)
        params = { :Action => name }
        args.each do |v|
          params.merge! v if v.kind_of? Hash
        end
        resp = call(name, params)
        super unless resp.valid?
        return resp
      end
    end
    # End inner classes

    def supports(source)
      true
    end

    def auto_capture?
      true
    end

    def method_type
      'amazon_fps'
    end

    def provider_class
      return ::Spree::Gateway::AmazonFps
    end

    def is_sandbox?
      preferred_server.present? && preferred_server == 'sandbox'
    end

    def get(pref, default=nil)
      val = self.send(('preferred_'+pref.to_s).to_sym)
      if val.present?
        return val
      else
        raise ArgumentError unless default
      end
    end

    def sign_params(parameters, verb, uri = nil)
      uri = end_point_uri if uri.nil?
      ::Amazon::FPS::SignatureUtils.sign_parameters({
          parameters: parameters,
          aws_secret_key: get(:secret_key),
          host: uri.host,
          verb: verb,
          uri: (uri.path.empty? ? '/' : uri.path),
          algorithm: parameters[:signatureMethod] || parameters[:SignatureMethod]
        })
    end

    def end_point_url_str
      "https://authorize.#{is_sandbox? ? 'payments-sandbox' : 'payments'}.amazon.com/pba/paypipeline"
    end

    def end_point_uri
      URI.parse end_point_url_str
    end

    def api_call_uri(options)
      uri = URI("https://fps#{is_sandbox? ? '.sandbox' : ''}.amazonaws.com/")

      options[:AWSAccessKeyId] = get(:access_key)
      options[:SignatureVersion] = 2
      options[:SignatureMethod] = 'HmacSHA256' unless options[:SignatureMethod]
      options[:Timestamp] = Time.now.utc.iso8601
      options[:Version] = '2008-09-17'
      options.delete :Signature if options[:Signature]
      options[:Signature] = sign_params(options, 'GET', uri)

      # Weird workaround for a bug that causes Hash#sort to raise an error 
      # if keys in the hash contains dots. For the workaround, I use 
      # underscores instead.
      options = Hash[options.map { |k,v| [k.to_s.gsub('_','.'), v] }]

      puts '#################API_CALL#################'
      puts 'uri: ' + uri.to_s
      puts 'options: ' + options.to_s

      uri.query = options.to_query

      puts 'full path: ' + uri.to_s
      puts '##########################################'

      uri
    end

    def api
      ApiCall.new(self)
    end

    def purchase(amount, checkout, options)
      resp = api.GetTransactionStatus :TransactionId => checkout.transaction_id

      result = Class.new do
        def initialize(s); @success = s; end
        def success?; @success; end
        def authorization; nil; end
      end.new resp.StatusCode == 'Success'

      if result.success?
        checkout.status = 'Complete'
      else
        checkout.status = 'Failed'
      end
      checkout.save

      result
    end

    def refund(payment, amount)
      resp = api.Refund ({
        :CallerReference      => "#{payment.source.transaction_id}-refund",
        :RefundAmount_CurrencyCode => 'USD',
        :RefundAmount_Value       => amount,
        :TransactionId => payment.source.transaction_id
      })
      if !resp.error && resp.TransactionStatus != 'Cancelled' && resp.TransactionStatus != 'Failure'
        payment.source.update_attributes({
          refunded_at: Time.now,
          refund_transaction_id: resp.TransactionId,
          status: 'Refunded'
        })

        payment.class.create!(
          order: payment.order,
          source: payment,
          payment_method: payment.payment_method,
          amount: amount.to_f * -1,
          response_code: resp.TransactionId,
          state: 'completed'
        )
      end
      resp
    end
  end
end