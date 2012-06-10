require File.expand_path('../lib/attr_default/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_dependency 'rake'
  gem.add_dependency 'rails'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'hobofields'
  gem.authors       = ["Colin Kelley", "Nick Burwell"]
  gem.email         = ["colindkelley@gmail.com"]
  gem.description   = %q{Dynamic Ruby defaults for ActiveRecord attributes}
  gem.summary       = %q{Dynamic Ruby defaults for ActiveRecord attributes. These are lazy evaluated just in time: when first accessed, or just before validation or save. This allows dynamic defaults to depend on attributes that are assigned after initialization, or on other dynamic defaults.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/.*\.rb})
  gem.name          = "attr_default"
  gem.require_paths = ["lib"]
  gem.version       = AttrDefault::VERSION
end
