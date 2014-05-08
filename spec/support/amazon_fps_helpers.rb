module AmazonFpsHelpers
	def amazon_access_key
		grab('access_key') or 'AKIAJRZRFCCMMSLTZSEQ'
	end
	def amazon_secret_key
		grab('secret_key') or '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'
	end
	def amazon_email
		grab('email') or 'spree-amazon-fps@mailinator.com'
	end
	def amazon_password
		grab('password') or '6dY4haWB'
	end

	def amazon_fps_url
    'https://payments-sandbox.amazon.com/sdui/sdui/overview'
  end

private
	def grab(name)
		filename = "#{Rails.root}/config/amazon_fps_tests.yml"
		return unless File.exists? filename
		YAML.load_file(filename)[name]
	end

end