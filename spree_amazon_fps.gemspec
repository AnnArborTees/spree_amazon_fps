# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_amazon_fps'
  s.version     = '0.1.0'
  s.summary     = 'Amazon Flexible Payment System'
  s.description = 'Adds Amazon Flexible Payment System to Spree Payment Methods'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Nigel Baillie'
  s.email     = 'metreckk@gmail.com'
  # s.homepage  = 'http://www.spreecommerce.com'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 2.2.1'
  s.add_dependency 'spree_backend', '~> 2.2.1'
  s.add_dependency 'spree_frontend', '~> 2.2.1'
  s.add_dependency 'spree_api', '~> 2.2.1'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.4'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
