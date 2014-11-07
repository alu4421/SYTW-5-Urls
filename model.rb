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
  property  :city,        String

  belongs_to :shorturl

  before :create, :set_country
  after :create, :set_city

  def set_country
    xml = RestClient.get "http://freegeoip.net/xml/#{ip}"
    self.country = XmlSimple.xml_in(xml.to_s, { 'ForceArray' => false })['CountryName'].to_s
    self.save
  end

  def set_city
    xml = RestClient.get "http://freegeoip.net/xml/#{ip}"
    self.city = XmlSimple.xml_in(xml.to_s, { 'ForceArray' => false })['RegionName'].to_s
    self.save
  end

end