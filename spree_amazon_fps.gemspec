# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_amazon_fps'
  s.version     = '1.0.0'
  s.summary     = 'Amazon Flexible Payment System'
  s.description = 'Adds Amazon Flexible Payment System to Solidus Payment Methods'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Nigel Baillie (Ann Arbor T-Shirt Company, LLC)'
  s.email     = 'metreckk@annarbortees.com'
  s.homepage  = 'http://www.annarbortees.com'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'solidus_core', '~> 1.2'
  s.add_dependency 'solidus_backend', '~> 1.2'
  s.add_dependency 'solidus_frontend', '~> 1.2'
  s.add_dependency 'solidus_api', '~> 1.2'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.4'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails', '~> 3.0'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'byebug'
end
