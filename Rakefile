# Bootstrap
#-----------------------------------------------------------------------------#

desc 'Initializes your working copy to run the specs'
task :bootstrap do
  puts 'Updating submodules...'
  `git submodule update --init --recursive`

  if system('which bundle')
    puts 'Installing gems'
    `bundle install`
  else
    $stderr.puts red("[!] Please install the bundler gem manually:\n" \
      '    $ [sudo] gem install bundler')
	exit 1
  end
end

begin

	require 'bundler/gem_tasks'

	# Spec
	#-----------------------------------------------------------------------------#

	namespace :spec do
		def specs(dir)
			FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
		end

		desc 'Automatically run specs for updated files'
		task :kick do
			exec 'bundle exec kicker -c'
		end

		task :all do
			title 'Running Unit Tests'
			sh "bundle exec bacon #{specs('**')}"

			title 'Checking code style...'
			Rake::Task['rubocop'].invoke
		end
	end



	desc 'Run all specs'
	task :spec => 'spec:all'

	# Coverage
	#-----------------------------------------------------------------------------#

	desc 'Generates & opens the coverage report'
	task :coverage do
		title 'Generating Coverage Report'
		sh "env GENERATE_COVERAGE=true bundle exec bacon --quiet #{specs('**')}"
		title 'Opening Report'
		puts 'Coverage report available at `coverage/index.html`'
		sh 'open coverage/index.html'
	end

	# Rubocop
	#-----------------------------------------------------------------------------#

	desc 'Checks code style'
	task :rubocop do
		if RUBY_VERSION >= '1.9.3'
			require 'rubocop'
			cli = Rubocop::CLI.new
			result = cli.run
			abort('RuboCop failed!') unless result == 0
		else
			puts '[!] Ruby > 1.9 is required to run style checks'
		end
	end

rescue LoadError
  $stderr.puts red('[!] Some Rake tasks haven been disabled because the ' \
    'environment couldn’t be loaded. Be sure to run `rake bootstrap` first.')
end

# Helpers
#-----------------------------------------------------------------------------#

task :default => :spec

def title(title)
  cyan_title = "\033[0;36m#{title}\033[0m"
  puts
  puts '-' * 80
  puts cyan_title
  puts '-' * 80
  puts
end
