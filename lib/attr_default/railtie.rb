module AttrDefault
  # Rails 3 initialization
  def self.initialize_railtie
    ActiveSupport.on_load :active_record do
      AttrDefault.initialize_active_record_extensions
    end
  end
  
  def self.initialize_active_record_extensions
    ActiveRecord::Base.extend(AttrDefault::ClassMethods)
  end
  
  class Railtie < Rails::Railtie
    initializer 'attr_default.insert_into_active_record' do
      AttrDefault.initialize_railtie
    end
  end
end
