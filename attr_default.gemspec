# frozen_string_literal: true

require_relative 'lib/attr_default/version'

Gem::Specification.new do |gem|
  gem.name          = "attr_default"
  gem.require_paths = ["lib"]
  gem.version       = AttrDefault::VERSION
  gem.authors       = ["Invoca Development"]
  gem.email         = ["development@invoca.com"]
  gem.description   = %q{Dynamic Ruby defaults for ActiveRecord attributes}
  gem.summary       = %q{Dynamic Ruby defaults for ActiveRecord attributes. These are lazy evaluated just in time: when first accessed, or just before validation or save. This allows dynamic defaults to depend on attributes that are assigned after initialization, or on other dynamic defaults.}
  gem.homepage      = "https://github.com/Invoca/attr_default"
  gem.metadata = {
    "allowed_push_host" => "https://rubygems.org"
  }

  gem.metadata = {
    'allowed_push_host' => 'https://rubygems.org'
  }

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/.*\.rb})

  gem.add_dependency 'rails', '~> 4.2'
end
