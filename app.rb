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

#Database Configuration
  configure :development, :test do
    DataMapper.setup( :default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/urls.db" )
  end

  configure :production do
    DataMapper.setup(:default, ENV['DATABASE_URL'])
  end

  DataMapper::Logger.new($stdout, :debug)
  DataMapper::Model.raise_on_save_failure = true 

  DataMapper.finalize

  #DataMapper.auto_migrate!
  DataMapper.auto_upgrade! #No delete information, update
#End Database Configuration

require_relative 'model'

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
    @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20, :email => session[:email])
  else
    @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20, :email => "")
  end
  haml :index
end

#Redirect
get '/auth/:name/callback' do
    session[:auth] = @auth = request.env['omniauth.auth']
    session[:email] = @auth['info'].email
    session[:nombre] = @auth['info'].name
    if session[:auth] then
      @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20, :email => session[:email])
      haml :index
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
      if params[:opc_url] == ""
        @short_url = ShortenedUrl.first_or_create(:url => params[:url], :opc_url => params[:opc_url], :email => session[:email])
      else
        @short_opc_url = ShortenedUrl.first_or_create(:url => params[:url], :opc_url => params[:opc_url], :email => session[:email])
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
  short_url = ShortenedUrl.first(:id => params[:shortened].to_i(Base), :email => session[:email])
  #URLs witho short urls, we use 
  #URLs con parametros urls corto, por lo que se usara el campo opc_url
  short_opc_url = ShortenedUrl.first(:opc_url => params[:shortened], :email => session[:email])

  if short_opc_url #Si tiene información, entonces devolvera por opc_ulr
    redirect short_opc_url.url, 301
  else
    redirect short_url.url, 301
  end
end


error do haml :index end
