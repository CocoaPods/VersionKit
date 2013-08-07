require "bundler/gem_tasks"

desc "Run the specs"
task :specs do
  files = FileList["spec/**/*_spec.rb"].shuffle.join(' ')
  sh "GENERATE_COVERAGE=true bundle exec bacon #{files}"
end

task :default => :specs
