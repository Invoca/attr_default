# frozen_string_literal: true

unless ENV["NO_COVERAGE"] == "true"
  require "simplecov"

  SimpleCov.start do
    add_filter "/test/"
    track_files "lib/**/*.rb"

    if ENV["GITHUB_ACTIONS"]
      require "simplecov-lcov"

      SimpleCov::Formatter::LcovFormatter.config do |config|
        config.report_with_single_file = true
        config.single_report_path = "coverage/lcov.info"
      end

      formatter SimpleCov::Formatter::LcovFormatter
    else
      formatter SimpleCov::Formatter::HTMLFormatter
    end
  end
end
