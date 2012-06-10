module AttrDefault
  module ClassMethods
    def attr_default attr_name, default
      if !method_defined?(:_attr_default_set)
        include AttrDefault
      end

      attr_name = attr_name.to_s
      define_method attr_name do
        if new_record? && !@_attr_defaults_set_from_clone && !_attr_default_set[attr_name]
          default_value = Proc === default ? instance_eval(&default) : default.dup
          send "#{attr_name}=", default_value
        end
        read_attribute_with_fixups( attr_name )
      end

      define_method "#{attr_name}=" do |*args|
        _attr_default_set[attr_name] = true
        write_attribute_with_fixups( attr_name, args )
      end

      touch_proc = lambda { |obj| obj.send(attr_name); true }
      before_validation   touch_proc
      before_save         touch_proc
    end

    # Hobo Fields field declaration
    def field_added(name, type, args, options)
      if (default = options[:ruby_default]) && Proc === default
        attr_default name, default
      elsif (default = options[:default]) && Proc === default
        attr_default name, default
        options.delete(:default)
        options[:ruby_default] = default
      end
    end
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

  def clone
    result = super
    result.created_at = nil unless !result.class.columns_hash.has_key?('created_at')
    result.updated_at = nil unless !result.class.columns_hash.has_key?('updated_at')
    if self.new_record?
      result.instance_variable_set(:@_attr_default_set, self._attr_default_set.dup)
    else
      result.instance_variable_set(:@_attr_defaults_set_from_clone, true)
    end
    result
  end
end

if defined?(Rails::Railtie)
  require 'attr_default/railtie'
else
  # Rails 2 initialization
  ActiveRecord::Base.extend(AttrDefault::ClassMethods)
end
