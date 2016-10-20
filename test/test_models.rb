
module SomeOtherModule

end

class TestUser < ActiveRecord::Base
  attr_accessor     :password
  attr_default      :password, '<none>'

  if ENV['INCLUDE_HOBO']
    fields do
      first_name    :string, :default => '', :ruby_default => lambda { 'John' }
      last_name     :string, :ruby_default => 'Doe'
      domain        :string, :ruby_default => 'default.com'
      timestamp     :timestamp, :default => lambda { (Time.zone || ActiveSupport::TimeZone['Pacific Time (US & Canada)']).now }
    end
  else
    attr_default :first_name, 'John'
    attr_default :last_name, 'Doe'
    attr_default :domain, 'default.com'
    attr_default :timestamp, lambda { (Time.zone || ActiveSupport::TimeZone['Pacific Time (US & Canada)']).now }
  end

  has_many :test_domains
  has_many :test_domains_subclass, :class_name => 'TestDomainSubclass'
end

class TestDomain < ActiveRecord::Base
  if ENV['INCLUDE_HOBO']
    fields do
      domain      :string, :default => lambda { test_user.domain }
      path        :string, :ruby_default => "/path"
    end
  else
    attr_default :domain, lambda { test_user.domain }
    attr_default :path, "/path"
  end

  belongs_to :test_user
end

class TestDomainSubclass < TestDomain
  include SomeOtherModule
  if ENV['INCLUDE_HOBO']
    fields do
      domain      :string, :default => lambda { "sub_#{test_user.domain}" }
    end
  else
    attr_default :domain, lambda { "sub_#{test_user.domain}" }
  end
end


