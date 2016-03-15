require 'sinatra/base'
require 'json'
require 'pathname'
require 'fileutils'
APP_ROOT = Pathname.new(File.dirname(__FILE__))
$: << APP_ROOT.join('lib').to_s
require 'validator'
require 'deployer'

class App < Sinatra::Base
  enable :dump_errors

  get '/' do
    'Ploy'
  end

  post '/ploy' do
    deployer = Deployer.new(params)
    result = deployer.run
    content_type :json
    status 403 if result[:error]
    JSON.generate result
  end

end

