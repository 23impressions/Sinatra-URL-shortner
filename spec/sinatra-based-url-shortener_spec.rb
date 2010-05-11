require File.dirname(__FILE__) + '/spec_helper'

describe SinatraBasedUrlShortener do
  include Rack::Test::Methods

  # for Rack::Test (which lets us test the response code, because Capybara doesn't support this)
  #
  # when we use get('/'), we are using Rack::Test
  #
  # when we visit('/'), we are using Capybara
  #
  def app
    SinatraBasedUrlShortener.new
  end

  before do
    UniqueSLUG.all.destroy
    SinatraBasedUrlShortener.ssl_required = false
    SinatraBasedUrlShortener.basic_auth_required = false
  end

  it 'should be able to shorten a URL' do
    Url.count.should == 0

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.count.should == 1
    Url.first.url.should  == 'http://www.google.com/'
    Url.first.slug.should == 'aaa'

    visit '/'
    fill_in 'url', :with => 'http://www.not-google.com/'
    click_button 'Shorten'

    Url.count.should == 2
    Url.last.url.should  == 'http://www.not-google.com/'
    Url.last.slug.should == 'aab'
  end

  it 'should return the same unique slug for identical URLs' do
    Url.count.should == 0

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.count.should == 1
    Url.first.url.should  == 'http://www.google.com/'
    Url.first.slug.should == 'aaa'

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.count.should == 1 # did not create a new one
  end

  it 'should redirect you to the full URL when you visit the slug' do
    get '/aaa'
    last_response.status.should == 404

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'
    
    get '/aaa'
    last_response.status.should == 302
    last_response.headers['Location'].should == 'http://www.google.com/'
  end

  it 'tracks clicked URLs' do
    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.first.clicks.count.should == 0
    
    get '/aaa'
    Url.first.clicks.count.should == 1
    Url.first.clicks.first.ip_address.should == '127.0.0.1'
    Url.first.clicks.first.created_at.should_not be_nil
    Url.first.clicks.first.referrer.should == '/'

    get '/aaa'
    Url.first.clicks.count.should == 2
  end

  it 'can view the history of a shortened url' do
    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'
    
    visit '/aaa/history'
    page.should have_no_content('127.0.0.1')
  end

  it 'requires SSL when you POST to / (if SinatraBasedUrlShortener.ssl_required?)' do
    SinatraBasedUrlShortener.ssl_required = true
    get '/'
    last_response.body.should include('https://') # <-- the form should POST to an https:// url

    post '/', :url => 'http://www.google.com'
    last_response.status.should == 403
    Url.count.should == 0

    SinatraBasedUrlShortener.ssl_required = false
    get '/'
    last_response.body.should_not include('https://') # no https:// url should be present

    post '/', :url => 'http://www.google.com'
    last_response.status.should == 200
    Url.count.should == 1
  end

  it 'requires HTTP Basic Auth when you POST to / (if SinatraBasedUrlShortener.basic_auth_required?)' do
    SinatraBasedUrlShortener.basic_auth_required = true

    post '/', :url => 'http://www.google.com'
    last_response.status.should == 401
    Url.count.should == 0

    authorize 'admin', 'admin'

    post '/', :url => 'http://www.google.com'
    last_response.status.should == 200
    Url.count.should == 1
  end

end
