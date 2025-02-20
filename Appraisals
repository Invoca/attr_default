# frozen_string_literal: true

require 'appraisal/matrix'

appraisal_matrix(rails: "7.0") do |rails:|
  if rails <= "7.0"
    gem 'sqlite3', '~> 1.4'
  else
    gem 'sqlite3'
  end
end
