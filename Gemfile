source 'https://rubygems.org'

gemspec

# pg 1.6 dropped support for Ruby < 3.0; keep the Rails 5.2/6.0 CI rows (Ruby 2.7)
# on the last 2.x-compatible pg line. Newer Rubies take the current pg.
gem 'pg', RUBY_VERSION < '3.0' ? '~> 1.5.9' : '>= 1.5'
