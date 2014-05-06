module FeatureHelpers
	def object_with(funcs)
		Class.new do
			def initialize(f); @funcs=f; end
			def respond_to?(name)
				super or (if @funcs[name] then true else false end)
			end
			def method_missing(name, *args, &block)
				super unless @funcs[name]
				@funcs[name].call(*args, &block)
			end
		end.new(funcs)
	end
end
