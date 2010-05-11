class Click
  include DataMapper::Resource

  property :id,         Serial
  property :ip_address, String
  property :referrer,   String, :length => 255

  timestamps :at

  belongs_to :url

end
