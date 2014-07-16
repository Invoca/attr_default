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
        read_attribute_with_fixups(attr_name)
      end

      define_method("#{attr_name}=") do |*args|
        _attr_default_set[attr_name] = true
        write_attribute_with_fixups(attr_name, args)
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

    def read_attribute_with_fixups(attr_name)
      if needs_time_zone_fixup?(attr_name)
        cached = @attributes_cache[attr_name] and return cached
        time = read_attribute(attr_name)
        @attributes_cache[attr_name] = time.acts_like?(:time) ? time.in_time_zone : time
      else
        read_attribute(attr_name)
      end
    end

    def write_attribute_with_fixups(attr_name, args)
      if needs_time_zone_fixup?(attr_name)
        time = args.first
        unless time.acts_like?(:time)
          time = time.is_a?(String) ? Time.zone.parse(time) : time.to_time rescue time
        end
        time = time.in_time_zone rescue nil if time
        write_attribute(attr_name, time)
      else
        write_attribute(attr_name, *args)
      end
    end

    def needs_time_zone_fixup?(attr_name)
      self.class.send(:create_time_zone_conversion_attribute?, attr_name, self.class.columns_hash[attr_name])
    end
    
    def copy(opts = {})
      if opts.key? :new_record
        result = 
          if defined?(super)
            super(opts)
          else
            if opts[:new_record]
              self.copy_new_record_true
            else
              self.copy_new_record_false # self.dup # what kind of default logic do we wire in
            end
          end
        result.created_at = nil unless !result.class.columns_hash.has_key?('created_at')
        result.updated_at = nil unless !result.class.columns_hash.has_key?('updated_at')
        if self.new_record?
          result.instance_variable_set(:@_attr_default_set, self._attr_default_set.dup)
        else
          result.instance_variable_set(:@_attr_defaults_set_from_dup, true)
        end
        result
      else
        # eventually phase this out with required keywords in ruby 2.0
        raise ArgumentError, "Ambiguous call to copy please provide :new_record => (true|false)"
      end
    end

    if Gem.loaded_specs['activesupport'].version >= Gem::Version.new('3.1')
      def copy_new_record_true
        dup
      end

      def copy_new_record_false
        clone
      end
    else
      def copy_new_record_true
        clone
      end

      def copy_new_record_false
        dup
      end
    end
  end
end

if defined?(Rails::Railtie)
  require 'attr_default/railtie'
else
  # Rails 2 initialization
  ActiveRecord::Base.extend(AttrDefault::ClassMethods)
end
