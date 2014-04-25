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
				raise ActiveRecord::RecordNotFound unless default
				return default
			end
		end

		def sign_params(parameters, secret_key, uri, verb)
			::Amazon::FPS::SignatureUtils.sign_parameters({
					parameters: parameters,
					aws_secret_key: secret_key,
					host: uri.host,
					verb: verb,
					uri: uri.path,
					algorithm: parameters['signatureMethod']
				})
		end

		def end_point_url
			URI.parse "https://authorize.#{is_sandbox? ? 'payments-sandbox' : 'payments'}.amazon.com/pba/paypipeline"
		end

		def purchase(amount, source, options)
			
		end
	end
end