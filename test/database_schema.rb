# frozen_string_literal: true

if RUBY_PLATFORM == "java"
  database_adapter = "jdbcsqlite3"
else
  database_adapter = "sqlite3"
end

DUP_METHODS =
    if Gem.loaded_specs['activesupport'].version >= Gem::Version.new('4.0')
      [:dup]
    elsif Gem.loaded_specs['activesupport'].version >= Gem::Version.new('3.1')
      [:dup, :clone]
    else
      [:clone]
    end

database_file = ENV['SQLITE3_FILE_PATH'].presence || 'test/test.sqlite3'

File.unlink(database_file) rescue nil
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Base.establish_connection(
    :adapter => database_adapter,
    :database => database_file
)

ActiveRecord::Base.connection.create_table(:test_users, :force => true) do |t|
  t.string :first_name, :default => ''
  t.string :last_name
  t.string :domain, :default => 'example.com'
  t.string :password
  t.timestamp :timestamp
end

ActiveRecord::Base.connection.create_table(:test_domains, :force => true) do |t|
  t.string  :type
  t.integer :test_user_id
  t.string :domain, :default => 'domain.com'
  t.string :path
  t.timestamp :created_at
end

