require 'sinatra/base'

class RestAPI < Sinatra::Base

  get '/' do
    'Dysprosium'
  end

  get '/dy/load/:document' do
    import 'document'
    content_type :json
    JSON.generate Document.commands(params[:document])
  end
end
