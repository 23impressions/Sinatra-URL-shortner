require File.dirname(__FILE__) + '/sinatra-based-url-shortener'

if ENV['RACK_ENV'] == 'production'
  SinatraBasedUrlShortener.ssl_required = true
  SinatraBasedUrlShortener.basic_auth_required = true
end

dev_db = "sqlite3://#{ File.expand_path(File.dirname(__FILE__) + '/development.sqlite3') }"

DataMapper.setup :default, ENV['DATABASE_URL'] || dev_db
DataMapper.auto_upgrade!

run SinatraBasedUrlShortener.new
