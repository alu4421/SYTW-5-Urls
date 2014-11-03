require 'restclient'
require 'xmlsimple'
require 'dm-core'
require 'dm-migrations'

class Shorturl
  include DataMapper::Resource
	  property :id, Serial
	  property :url, Text
	  property :opc_url, Text
	  property :email, Text
    property :created_at, DateTime
    property :n_visits, Integer

	  has n, :visits
end

class Visit
  include DataMapper::Resource

  property  :id,          Serial
  property  :created_at,  DateTime
  property  :ip,          IPAddress
  property  :country,     String

  belongs_to :shorturl
end