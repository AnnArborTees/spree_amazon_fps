module Amazon
module FPS

	class ApiCall
		def initialize(amazon_gateway)
			@amazon = amazon_gateway
		end

		def respond_to?(meth)
			true
		end

		def method_missing(meth, *args, &block)
			params = { :Action => meth }
			args.each do |v|
				params.merge! v if v.kind_of? Hash
			end
			Net::HTTP.get @amazon.api_call_uri(params)
		end
	end

end
end