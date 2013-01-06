require 'rubygems'
require 'active_support'
require 'active_support/dependencies'
require 'active_record'
ActiveRecord::ActiveRecordError # work-around from https://rails.lighthouseapp.com/projects/8994/tickets/2577-when-using-activerecordassociations-outside-of-rails-a-nameerror-is-thrown
require 'test/unit'
require 'active_support/core_ext/logger'
require 'hobofields' if ENV['INCLUDE_HOBO']

$LOAD_PATH.unshift File.expand_path("lib", File.dirname(__FILE__))
require 'attr_default'
Dir.chdir(File.dirname(__FILE__))

if RUBY_PLATFORM == "java"
  database_adapter = "jdbcsqlite3"
else
  database_adapter = "sqlite3"
end

File.unlink('test.sqlite3') rescue nil
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Base.establish_connection(
  :adapter => database_adapter,
  :database => 'test.sqlite3'
)

ActiveRecord::Base.connection.create_table(:test_users, :force => true) do |t|
  t.string :first_name, :default => ''
  t.string :last_name
  t.boolean :managed, :default => false
  t.timestamp :timestamp
end

ActiveRecord::Base.connection.create_table(:test_numbers, :force => true) do |t|
  t.string  :type
  t.integer :test_user_id
  t.integer :number
  t.boolean :managed
  t.timestamp :created_at
end

if defined?(Rails::Railtie)
  AttrDefault.initialize_railtie
  AttrDefault.initialize_active_record_extensions
end

class TestUser < ActiveRecord::Base
  attr_accessor     :password
  attr_default      :password, '<none>'

  if ENV['INCLUDE_HOBO']
    fields do
      first_name    :string, :default => '', :ruby_default => lambda { 'John' }
      last_name     :string, :ruby_default => 'Doe'
      timestamp     :timestamp, :default => lambda { (Time.zone || ActiveSupport::TimeZone['Pacific Time (US & Canada)']).now }
    end
  else
    attr_default :first_name, 'John'
    attr_default :last_name, 'Doe'
    attr_default :timestamp, lambda { (Time.zone || ActiveSupport::TimeZone['Pacific Time (US & Canada)']).now }
  end

  has_many :test_numbers
  has_many :test_numbers_subclass, :class_name => 'TestNumberSubclass'
end

class TestNumber < ActiveRecord::Base
  if ENV['INCLUDE_HOBO']
    fields do
      managed       :boolean, :default => lambda { test_user.managed }
    end
  else
    attr_default :managed, lambda { test_user.managed }
  end

  belongs_to :test_user
end

class TestNumberSubclass < TestNumber
  if ENV['INCLUDE_HOBO']
    fields do
      managed       :boolean, :default => lambda { false }
    end
  else
    attr_default :managed, lambda { false }
  end
end


class AttrDefaultTest < Test::Unit::TestCase
  def define_model_class(name = "TestClass", parent_class_name = "ActiveRecord::Base", &block)
    Object.send(:remove_const, name) rescue nil
    eval("class #{name} < #{parent_class_name}; end", TOPLEVEL_BINDING)
    klass = eval(name, TOPLEVEL_BINDING)
    klass.class_eval do
      if respond_to?(:table_name=)
        self.table_name = 'numbers'
      else
        set_table_name 'numbers'
      end
    end
    klass.class_eval(&block) if block_given?
  end

  def test_use_default_if_not_set
    u = TestUser.new
    assert_equal '', u.read_attribute(:first_name)
    assert_equal "Doe", u.last_name
  end

  def test_return_the_ActiveRecord_native_type_not_the_lambda_type
    u = TestUser.new
    assert_equal 'ActiveSupport::TimeWithZone', u.timestamp.class.name
    begin
      old_time_zone, Time.zone = Time.zone, 'Central Time (US & Canada)'
      u = TestUser.new
      assert_equal 'ActiveSupport::TimeWithZone', u.timestamp.class.name
      assert_match /Central Time/, u.timestamp.time_zone.to_s
    ensure
      Time.zone = old_time_zone
    end
  end

  def test_allow_an_override_to_be_specified
    u = TestUser.new(:last_name => "override")
    assert_equal "override", u.read_attribute(:last_name)
    assert_equal "override", u.last_name
  end

  def test_proc_default_value_for_string_and_symbol
    u = TestUser.new(:first_name => "override")
    u.save!
    assert_equal "override", u.first_name
    assert_equal "John", u.default_value_for("first_name")
    assert_equal "John", u.default_value_for(:first_name)
  end

  def test_nonproc_default_value_for_string_and_symbol
    u = TestUser.new(:managed => true)
    u.save!
    assert_equal true, u.managed
    assert_equal false, u.default_value_for("managed")
    assert_equal false, u.default_value_for(:managed)
  end

  def test_reset_to_default_value_string
    u = TestUser.create!(:last_name => "override")
    assert_equal "override", u.last_name
    u.reset_to_default_value("last_name")
    assert_equal "Doe", u.last_name
  end

  def test_reset_to_default_value_symbol
    u = TestUser.create!(:last_name => "override")
    assert_equal "override", u.last_name
    u.reset_to_default_value(:last_name)
    assert_equal "Doe", u.last_name
  end

  if ENV['INCLUDE_HOBO']
    def test_hobo_allow_default_and_ruby_default
      u = TestUser.new
      assert_equal "", u.read_attribute(:first_name)
      assert_equal "", TestUser.field_specs['first_name'].options[:default]
      assert_equal "John", TestUser.field_specs['first_name'].options[:ruby_default].call
      assert_equal "John", u.first_name
    end
  end

  def test_handle_mutating_the_default_string
    u = TestUser.new
    u2 = TestUser.new

    assert_equal "John", u2.first_name
    assert_equal "Doe", u2.last_name
    u.first_name.upcase!
    u.last_name.upcase!
    assert_equal "John", u2.first_name # should not be JOHN
    assert_equal "Doe", u2.last_name  # should not be DOE

    u3 = TestUser.new
    assert_equal "John", u2.first_name
    assert_equal "Doe", u3.last_name
  end

  def test_use_default_when_saved_if_not_touched
    user = TestUser.create! :managed => true
    number = user.test_numbers.build

    number.save!
    number.reload
    assert_equal true, number.read_attribute(:managed)
    assert_equal true, number.managed
  end

  def test_clone_touched_state_when_cloned_before_save_new_record_true
    u = TestUser.new :first_name => 'John', :last_name => 'Doe'
    u.last_name = 'overridden'
    u2 = u.clone
    assert_equal 'overridden', u2.read_attribute(:last_name)
    assert_equal 'overridden', u2.last_name
  end

  def test_clone_touched_state_when_cloned_after_save_new_record_false
    u = TestUser.new :first_name => 'John', :last_name => 'Doe'
    u.last_name = 'overridden'
    u2 = u.clone
    u2.save!
    u.save!
    assert u.clone.instance_variable_get(:@_attr_defaults_set_from_clone)
    assert_equal 'overridden', u.clone.last_name
    ufind = TestUser.find(u.id)
    u3 = ufind.clone
    assert_equal 'overridden', u3.read_attribute(:last_name), u3.attributes.inspect
    assert_equal 'overridden', u3.last_name
    u3.save!
    assert_equal 'overridden', u2.read_attribute(:last_name)
    assert_equal 'overridden', u2.last_name
    assert_equal 'overridden', u3.read_attribute(:last_name)
    assert_equal 'overridden', u3.last_name
  end

  def test_use_default_when_saved_if_not_touched_and_validation_turned_off
    user = TestUser.create! :managed => true
    number = user.test_numbers.build :number => 42

    # not touched or saved yet, still empty
    assert_equal nil, number.read_attribute(:managed)

    number.save(false)

    # now it should be true
    assert_equal true, number.read_attribute(:managed)
    assert_equal true, number.managed
  end

  def test_use_value_set_on_object_even_when_first_loaded_from_db
    user = TestUser.create! :managed => true
    number = user.test_numbers.create! :number => 42, :managed => false
    number_find = TestNumber.find(number.id)
    assert_equal false, number_find.managed
  end

  [false, true].each do |user_managed|
    define_method "test_default_#{user_managed}_and_param_not_specified" do
      user = TestUser.create! :managed => user_managed
      number = user.test_numbers.build
      assert_equal user_managed, number.managed
    end

    define_method "test_default_#{user_managed}_and_#{!user_managed}_specified" do
      user = TestUser.create! :managed => true
      number = user.test_numbers.build :managed => !user_managed
      assert_equal !user_managed, number.managed
    end
  end

  def test_allow_subclass_to_override_the_default
    user = TestUser.create! :managed => true
    number = user.test_numbers.new
    assert_equal true, number.managed
    number_subclass = user.test_numbers_subclass.new
    assert_equal false, number_subclass.managed
  end

  def test_non_persistent_use_default_if_not_set
    user = TestUser.new
    assert_equal "<none>", user.password
  end

  def test_non_persistent_use_value_if_set_in_initialize
    user = TestUser.new :password => "supersecret"
    assert_equal "supersecret", user.password
  end

  def test_non_persistent_use_value_if_set_after_initialize
    user = TestUser.new
    user.password = "supersecret"
    assert_equal "supersecret", user.password
  end
end

