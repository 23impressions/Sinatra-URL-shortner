require File.dirname(__FILE__) + '/spec_helper'

describe Url do

  it 'requires a unique url' do
    Url.gen(:url => nil                    ).should_not be_valid
    Url.gen(:url => ''                     ).should_not be_valid
    Url.gen(:url => 'http://www.google.com').should     be_valid
    Url.gen(:url => 'http://www.google.com').should_not be_valid
    Url.gen(:url => 'http://www.zoozle.com').should     be_valid
  end

  it 'requires a unique slug' do
    Url.gen(:slug => nil  ).should_not be_valid
    Url.gen(:slug => ''   ).should_not be_valid
    Url.gen(:slug => 'aaa').should     be_valid
    Url.gen(:slug => 'aaa').should_not be_valid
    Url.gen(:slug => 'aab').should     be_valid
  end

  it 'normalizes URLs' do
    Url.new(:url => 'http://www.google.com').url.should  == 'http://www.google.com/'
    Url.new(:url => 'http://www.google.com/').url.should == 'http://www.google.com/'
  end

end
