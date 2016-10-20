module AttrDefault
  module ClassMethods
    def attr_default attr_name, default
      if !method_defined?(:_attr_default_set)
        include AttrDefault::InstanceMethods
      end

      attr_name = attr_name.to_s
      _attr_defaults[attr_name] = default

      define_method(attr_name) do
        if new_record? && !@_attr_defaults_set_from_dup && !_attr_default_set[attr_name]
          reset_to_default_value(attr_name)
        end
        read_attribute(attr_name)
      end

      define_method("#{attr_name}=") do |*args|
        _attr_default_set[attr_name] = true
        write_attribute(attr_name, *args)
      end

      touch_proc = lambda { |obj| obj.send(attr_name); true }
      before_validation   touch_proc
      before_save         touch_proc
    end

    # Hobo Fields field declaration
    def field_added(name, type, args, options)
      if (default = options[:ruby_default])
        attr_default name, default
      elsif (default = options[:default]) && default.is_a?(Proc)
        ActiveSupport::Deprecation.warn(':default => Proc has been deprecated. Use :ruby_default.', caller)
        attr_default name, default
        options.delete(:default)
        options[:ruby_default] = default
      end
    end

    def _attr_defaults
      @_attr_defaults ||= (superclass._attr_defaults.dup rescue nil) || {}
    end
  end

  module InstanceMethods
    def default_value_for(attr_name)
      attr_name = attr_name.to_s
      if self.class._attr_defaults.has_key?(attr_name)
        attr_default = self.class._attr_defaults[attr_name]
        attr_default.is_a?(Proc) ? instance_exec(&attr_default) : (attr_default.dup rescue attr_default)
      else
        column_data = self.class.columns_hash[attr_name] or raise ArgumentError, "#{self.class.name}##{attr_name} not found"
        column_data.default
      end
    end

    def reset_to_default_value(attr_name)
      send("#{attr_name}=", default_value_for(attr_name))
    end

    def _attr_default_set
      @_attr_default_set ||= {}
    end

    def dup
      result = super
      result.created_at = nil unless !result.class.columns_hash.has_key?('created_at')
      result.updated_at = nil unless !result.class.columns_hash.has_key?('updated_at')
      if self.new_record?
        result.instance_variable_set(:@_attr_default_set, self._attr_default_set.dup)
      else
        result.instance_variable_set(:@_attr_defaults_set_from_dup, true)
      end
      result
    end
    alias_method(:clone, :dup)
end

if defined?(Rails::Railtie)
  require 'attr_default/railtie'
else
  # Rails 2 initialization
  ActiveRecord::Base.extend(AttrDefault::ClassMethods)
end
