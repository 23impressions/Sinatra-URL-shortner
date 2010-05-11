class Url
  include DataMapper::Resource

  property :id,   Serial
  property :url,  String, :required => true, :unique => true, :unique_index => true, :length => 255
  property :slug, String, :required => true, :unique => true, :unique_index => true

  timestamps :at

  has n, :clicks

  def url= value
    self['url'] = URI.parse(value).normalize.to_s if value and not value.empty?
  end

  def self.shorten url_to_shorten
    url      = Url.first_or_new :url => url_to_shorten
    url.slug = UniqueSLUG.next
    url.save
    url
  end

end
