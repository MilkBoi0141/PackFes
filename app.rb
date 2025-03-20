require "logger"
require "bundler/setup"
Bundler.require
require "sinatra/reloader" if development?
require "./models.rb"

get '/' do
  erb :index
end