source 'https://rubygems.org'

gemspec

group :development do
  gem 'bacon'
  gem 'coveralls', :require => false
  gem 'mocha', '~> 0.11.4'
  gem 'mocha-on-bacon'
  gem 'prettybacon'

  # Ruby 1.8.7 fixes
  gem 'mime-types', '< 2.0'
  if RUBY_VERSION >= '1.9.3'
    gem 'rubocop'
  end
end

