# frozen_string_literal: true

require_relative "test_helper.rb"
require_relative "database_schema.rb"
require_relative "test_models.rb"


class AttrDefaultTest < Minitest::Test
  def test_use_default_if_not_set
    u = TestUser.new
    assert_equal '', u.read_attribute(:first_name)
    assert_equal "Doe", u.last_name
  end

  def test_return_the_ActiveRecord_native_type_not_the_lambda_type
    u = TestUser.new
    assert_equal ActiveSupport::TimeWithZone, u.timestamp.class
    begin
      old_time_zone, Time.zone = Time.zone, 'Central Time (US & Canada)'
      u = TestUser.new
      assert_equal ActiveSupport::TimeWithZone, u.timestamp.class
      assert_match /Central Time/, u.timestamp.time_zone.to_s
    ensure
      Time.zone = old_time_zone
    end
  end

  def test_return_the_ActiveRecord_native_type_not_the_lambda_type_on_create
    u = TestUser.create!
    u = TestUser.find(u.id)
    assert_equal ActiveSupport::TimeWithZone, u.timestamp.class
    begin
      old_time_zone, Time.zone = Time.zone, 'Central Time (US & Canada)'
      u = TestUser.new
      assert_equal ActiveSupport::TimeWithZone, u.timestamp.class
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
    u = TestUser.new(:domain => "initial.com")
    u.save!
    assert_equal "initial.com", u.domain
    assert_equal "default.com", u.default_value_for("domain")
    assert_equal "default.com", u.default_value_for(:domain)
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
    user = TestUser.create! :domain => "initial.com"
    domain = user.test_domains.build

    domain.save!
    domain.reload
    assert_equal "initial.com", domain.read_attribute(:domain)
    assert_equal "initial.com", domain.domain
  end

  def test_dup_and_clone_touched_state_when_duped_or_cloned_before_save_new_record_true
    DUP_METHODS.each do |dup|
      u = TestUser.new :first_name => 'John', :last_name => 'Doe'
      u.last_name = 'overridden'
      u2 = u.send(dup)
      assert_equal 'overridden', u2.read_attribute(:last_name)
      assert_equal 'overridden', u2.last_name
    end
  end

  def test_dup_and_clone_touched_state_when_duped_or_cloned_after_save_new_record_false
    DUP_METHODS.each do |dup|
      u = TestUser.new(:first_name => 'John', :last_name => 'Doe')
      u.last_name = 'overridden'
      u2 = u.send(dup)
      u2.save!
      u.save!
      assert u.send(dup).instance_variable_get(:@_attr_defaults_set_from_dup)
      assert_equal 'overridden', u.send(dup).last_name
      ufind = TestUser.find(u.id)
      u3 = ufind.send(dup)
      assert_equal 'overridden', u3.read_attribute(:last_name), u3.attributes.inspect
      assert_equal 'overridden', u3.last_name
      u3.save!
      assert_equal 'overridden', u2.read_attribute(:last_name)
      assert_equal 'overridden', u2.last_name
      assert_equal 'overridden', u3.read_attribute(:last_name)
      assert_equal 'overridden', u3.last_name
    end
  end

  def test_use_default_when_saved_if_not_touched_and_validation_turned_off
    user = TestUser.create! :domain => "initial.com"
    domain = user.test_domains.build

    # not touched or saved yet, still SQL default
    assert_equal "domain.com", domain.read_attribute(:domain)

    domain.save(SAVE_NO_VALIDATE)

    # now it should be set to Ruby default
    assert_equal "initial.com", domain.read_attribute(:domain)
    assert_equal "initial.com", domain.domain
  end

  def test_use_value_set_on_object_even_when_first_loaded_from_db
    user = TestUser.create! :domain => "initial.com"
    domain = user.test_domains.create! :domain => "domain.initial.com"
    number_find = TestDomain.find(domain.id)
    assert_equal "domain.initial.com", number_find.domain
  end

  ['example.com', 'domain.com', 'default.com'].each do |user_domain|
    define_method "test_default_#{user_domain}_and_param_not_specified" do
      user = TestUser.create! :domain => user_domain
      domain = user.test_domains.build
      assert_equal user_domain, domain.domain
    end

    define_method "test_default_#{user_domain}_and_other_specified" do
      user = TestUser.create! :domain => user_domain
      domain = user.test_domains.build :domain => "override.com"
      assert_equal "override.com", domain.domain
    end
  end

  def test_allow_subclass_to_override_the_default
    user = TestUser.create! :domain => 'initial.com'
    domain = user.test_domains.new
    assert_equal 'initial.com', domain.domain
    domain_subclass = user.test_domains_subclass.new
    assert_equal 'sub_initial.com', domain_subclass.domain
  end

  def test_subclass_uses_base_class_default
    user = TestUser.create! :domain => 'initial.com'
    domain = user.test_domains.new
    assert_equal '/path', domain.path
    domain_subclass = user.test_domains_subclass.new
    assert_equal '/path', domain_subclass.path
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
