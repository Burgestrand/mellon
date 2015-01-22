require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

require "yard"
YARD::Rake::YardocTask.new

task :console do
  exec *%w[bundle exec pry -r mellon]
end

task :default => :spec
