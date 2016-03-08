require 'faye/websocket'
require 'json'
require 'pathname'

APP_PATH = Pathname.new(File.dirname(__FILE__))
$: << APP_PATH.join('app').to_s

def import(s)
  # development
  load "#{s}.rb"

  # production
  require s
end

def show_env(env)
  env.select { |k,v| k.start_with?("HTTP_") }.each do |k,v|
    puts "#{k}: #{v}"
  end
end


App = lambda do |env|
  show_env(env)

  if Faye::WebSocket.websocket?(env)
    import 'websocket_handler'
    WebsocketHandler.new(Faye::WebSocket.new(env), $channel_registry).run
  else
    import 'rest_api'
    RestAPI.new.call(env)
    #[404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
  end
end

