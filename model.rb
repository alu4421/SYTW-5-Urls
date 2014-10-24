class ShortenedUrl
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :opc_url, Text
  property :email, Text
  
end

