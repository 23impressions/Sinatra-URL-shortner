%w( rubygems sinatra/base haml dm-core dm-aggregates dm-validations dm-timestamps ).each {|lib| require lib }
%w( unique_slug url click http_basic_auth ).each {|file| require File.dirname(__FILE__) + "/#{file}" }

class SinatraBasedUrlShortener < Sinatra::Base

  class << self
    attr_accessor :ssl_required, :basic_auth_required

    def ssl_required?
      (ssl_required == true) ? true : false
    end

    def basic_auth_required?
      (basic_auth_required == true) ? true : false
    end
  end

  helpers do
    include HttpBasicAuth # username and password are set in this module

    def full_url slug
      'http://' + request.host + '/' + slug
    end

    def ssl_path path
      if SinatraBasedUrlShortener.ssl_required?
        'https://' + request.host + path
      else
        path
      end
    end
  end

  get '/' do
    haml :index
  end

  post '/' do
    protected! if SinatraBasedUrlShortener.basic_auth_required?

    if SinatraBasedUrlShortener.ssl_required?
      # HTTP_X_FORWARDED_PROTO is set by Heroku (the scheme will show up as http)
      using_ssl = (request.scheme == 'https')
      using_ssl = (request.env['HTTP_X_FORWARDED_PROTO'] == 'https') unless using_ssl

      unless using_ssl
        status 403
        return "SSL Required"
      end
    end

    @url = Url.shorten params[:url]
    haml :index
  end

  get '/:slug/history' do |slug|
    @url = Url.first :slug => slug
    haml :history
  end

  get '/:slug' do |slug|
    @url = Url.first :slug => slug
    if @url
      @url.clicks.create :ip_address => request.ip, :referrer => request.referrer
      redirect @url.url
    else
      status 404
      "Not Found"
    end
  end

end
