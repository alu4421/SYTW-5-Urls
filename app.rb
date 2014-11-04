#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'uri'
require 'pp'
require 'data_mapper'
require 'omniauth-oauth2'      
require 'omniauth-google-oauth2'
require 'xmlsimple'
require 'restclient'
require 'chartkick'

#Database Configuration
  configure :development, :test do
    DataMapper.setup( :default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/main.db" )
  end

  configure :production do
    DataMapper.setup(:default, ENV['DATABASE_URL'])
  end

  DataMapper::Logger.new($stdout, :debug)
  DataMapper::Model.raise_on_save_failure = true 

  require_relative 'model'

  DataMapper.finalize

  #DataMapper.auto_migrate!
  DataMapper.auto_upgrade! #No delete information, update
#End Database Configuration

Base = 36 #base alfanumerica 36, no contiene la ñ para la ñ incorporar la base 64.

#User Control
  use OmniAuth::Builder do       
    config = YAML.load_file 'config/config.yml'
    provider :google_oauth2, config['identifier'], config['secret']
  end
    
  enable :sessions               
  set :session_secret, '*&(^#234a)'
#End User Control

get '/' do
  if session[:auth] then
    @list = Shorturl.all(:order => [ :id.asc ], :limit => 20, :email => session[:email])
  else
    @list = Shorturl.all(:order => [ :id.asc ], :limit => 20, :email => nil)
  end
  haml :index
end

#Redirect
get '/auth/:name/callback' do
    session[:auth] = @auth = request.env['omniauth.auth']
    session[:email] = @auth['info'].email
    session[:nombre] = @auth['info'].name
    if session[:auth] then
      @list = Shorturl.all(:order => [ :id.asc ], :limit => 20, :email => session[:email])
      redirect '/'
    end
    haml :index
end

get '/logout' do
  session.clear
  redirect '/'
end

post '/' do
  uri = URI::parse(params[:url])
  if uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS then
    begin
      if params[:opc_url] == nil
        @short_url = Shorturl.first_or_create(:url => params[:url], :opc_url => nil, :email => session[:email], :created_at => Time.now)
      else
        @short_opc_url = Shorturl.first_or_create(:url => params[:url], :opc_url => params[:opc_url], :email => session[:email], :n_visits => 0, :created_at => Time.now)
      end
    rescue Exception => e
      puts "EXCEPTION!"
      pp @short_url
      puts e.message
    end
  else
    logger.info "Error! <#{params[:url]}> is not a valid URL"
  end
  redirect '/'
end

get '/:shortened' do
  #URLs without short urls, we use id.
  short_url = Shorturl.first(:id => params[:shortened].to_i(Base), :email => session[:email])
  #URLs witho short urls, we use 
  #URLs con parametros urls corto, por lo que se usara el campo opc_url
  short_opc_url = Shorturl.first(:opc_url => params[:shortened], :email => session[:email])

  if short_opc_url then #Si tiene información, entonces devolvera por opc_ulr
    short_opc_url.n_visits += 1
    short_opc_url.save
    visits = Visit.new(:created_at => Time.now, :ip => get_remote_ip(env), :shorturl => short_opc_url)
    visits.save
    redirect short_opc_url.url, 301
  else
    redirect short_url.url, 301
  end

end

def get_remote_ip(env)
  puts "request.url = #{request.url}"
  puts "request.ip = #{request.ip}"
  if addr = env['HTTP_X_FORWARDED_FOR']
    puts "env['HTTP_X_FORWARDED_FOR'] = #{addr}"
    addr.split(',').first.strip
  else
    puts "env['REMOTE_ADDR'] = #{env['REMOTE_ADDR']}"
    env['REMOTE_ADDR']
  end
end

error do haml :index end
