source :rubygems

group :useful do
  gem 'heroku', :require => false
end

gem 'rails', '3.1.0.rc5'

gem 'bson_ext'
gem 'mongoid'

# Asset template engines
gem 'sass-rails', '~> 3.1.0.rc5'
gem 'coffee-script'
gem 'compass'

# JS niceties
gem 'jquery-rails'
gem 'pjax_rails'

gem 'pusher'

gem 'oa-oauth'
gem 'cancan'
gem 'devise'

gem 'kaminari'

group :production do
  gem 'dalli'
  gem 'therubyracer-heroku', '0.8.1.pre3'
end

group :staging, :production do
  gem 'uglifier'
end