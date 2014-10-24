# -*- coding: utf-8 -*-


ENV['RACK_ENV'] = 'test'
require_relative '../app.rb'
require 'minitest/autorun'
require 'rack/test'

include Rack::Test::Methods


def app
  Sinatra::Application
end

describe "Tests de la pagina raiz ('/') con metodo get" do
  it "Carga de la web desde el servidor" do
  get '/'
    assert last_response.ok?
  end

  it "El titulo deberia de ser" do
    get '/'
    assert_match "<title>SYTW URLS</title>", last_response.body
  end

  it "El foot deberia de contener" do
    get '/'
    assert_match %Q{<p class='pull-right'>Leinah ©Copyright 2014    </p>}, last_response.body
  end

end