require 'restclient'
require 'xmlsimple'
require 'dm-core'
require 'dm-migrations'

class ShortenedUrl
  include DataMapper::Resource
	  property :id, Serial
	  property :url, Text
	  property :opc_url, Text
	  property :email, Text

	  has n, :visits
end

class Visit
  include DataMapper::Resource

  property  :id,          Serial
  property  :created_at,  DateTime
  property  :ip,          IPAddress
  property  :country,     String
  belongs_to  :shortened_url


  after :create, :set_country 

  #def set_country
  #  xml = RestClient.get "http://api.hostip.info/get_xml.php?ip=#{ip}"
  #  self.country = XmlSimple.xml_in(xml.to_s)
  #  self.save
  #end

  #def get_remote_ip(env)
  #puts "request.url = #{request.url}"
  #puts "request.ip = #{request.ip}"
  #if addr = env['HTTP_X_FORWARDED_FOR']
  #  puts "env['HTTP_X_FORWARDED_FOR'] = #{addr}"
  #  addr.split(',').first.strip
  #else
  #  puts "env['REMOTE_ADDR'] = #{env['REMOTE_ADDR']}"
  #  env['REMOTE_ADDR']
  #end
	#end 
end