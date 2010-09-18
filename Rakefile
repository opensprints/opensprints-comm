task :default do
  sh "bacon --automatic --quiet"
end


begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "opensprints-comm"
    gemspec.summary = "Wrapper for the opensprints race manager hardware"
    gemspec.description = "Provides the library for interacting with the arduino firmware and also for mocking it out."
    gemspec.email = "luke@opensprints.org"
    gemspec.homepage = "http://github.com/lukeorland/opensprints-comm"
    gemspec.authors = ["Luke Orland"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
