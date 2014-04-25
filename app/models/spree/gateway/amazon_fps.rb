module Spree
	class Gateway::AmazonFps < Gateway
		preference :access_key, :string
		preference :secret_key, :string
		preference :server, :string, default: 'sandbox'
		preference :logourl, :string, default: ''

		def supports(source)
			true
		end

		def auto_capture?
			true
		end

		def method_type
			'amazon_fps'
		end

		def is_sandbox?
			preferred_server.present? && preferred_server == 'sandbox'
		end

		def get(pref, default=nil)
			val = self.send(('preferred_'+pref.to_s).to_sym)
			if val.present?
				return val
			else
				# TODO use a better error for this
				raise ArgumentError unless default
				return default
			end
		end

		def sign_params(parameters, secret_key, verb)
			::Amazon::FPS::SignatureUtils.sign_parameters({
					parameters: parameters,
					aws_secret_key: secret_key,
					host: end_point_uri.host,
					verb: verb,
					uri: end_point_uri.path,
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
			options[:AWSAccessKeyId] = get('access_key') unless options[:AWSAccessKeyId]
			options[:SignatureVersion] = 2
			options[:SignatureMethod] = 'HmacSHA256'
			options[:Timestamp] = Time.now.utc.iso8601
			options[:Version] = '2008-09-17'
			options[:Signature] = sign_params(options, get('secret_key'), 'GET') unless options[:Signature]
			
			uri = URI("https://fps#{is_sandbox? ? '.sandbox' : ''}.amazonaws.com/")
			uri.query = options.to_query
			uri
		end

		def purchase(amount, checkout, options)
			
		end
	end
end