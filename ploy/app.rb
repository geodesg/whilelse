require 'sinatra/base'
require 'json'
require 'pathname'
require 'fileutils'
APP_ROOT = Pathname.new(File.dirname(__FILE__))
$: << APP_ROOT.join('lib').to_s
require 'validator'

class App < Sinatra::Base
  enable :dump_errors

  get '/' do
    'Ploy'
  end

  post '/ploy' do
    mode = params['mode']
    # mode:
    #   default: 'service' - deploy a long-running service, takes a port as an argument
    #   'run' - run an app that should execute quickly, wait for exit and return output
    #   'frontend' - place file in frontend/app/generated/

    id = "#{(Time.now.to_f * 1000).to_i}#{rand.to_s[2..-1]}"
    cleanup_file = false

    contents = params['contents']
    user_token = params['user_token'] || random_string
    if mode == 'frontend'
      frontend_root = APP_ROOT.join('..', 'frontend', 'app', 'generated')
      raise "Invalid path: #{params['name']}" if ! Validator.valid_subpath?(params['name'])
      output_file_name = frontend_root.join(params['name']).to_s
    elsif mode == 'experiment'
      raise "Invalid file name: #{params['name']}" if ! Validator.valid_filename?(params['name'])
      frontend_root = APP_ROOT.join('..', 'tmp', 'experiments')
      output_file_name = experiment_root.join(params['name']).to_s
    else
      content_root = APP_ROOT.join('contents')
      cleanup_file = true
      output_file_name = content_root.join("app#{id}.js")
    end
    FileUtils.mkdir_p(File.dirname(output_file_name))
    puts "Writing to #{output_file_name}"
    puts contents
    puts
    File.open(output_file_name, 'w') do |f|
      f.write(contents)
    end

    case mode
    when 'service', nil
      # Kill user's current app, if any
      pid = store.get_user_pid(user_token)
      if pid
        puts "TERMINATING #{pid}"
        begin
          puts Process.kill "KILL", pid
        rescue Errno::ESRCH => e
          puts e.message
        end
      end

      port = find_a_port

      # Start new app
      pid = fork do
        Dir.chdir content_root.to_s
        puts "CHILD on port #{port}"
        exec "node app#{id}.js #{port}"
      end
      # TODO: clean up file when process terminates
      store.set_user_pid(user_token, pid)
      puts "FORKED #{pid}"

      Thread.new(pid, user_token, &method(:expire_process))

      content_type :json
      JSON.generate({ url: "#{ENV['DEPLOY_PROTOCOL']}//#{ENV['DEPLOY_HOSTNAME']}:#{port}/" })

    when 'run'
      Dir.chdir content_root.to_s
      output = `node app#{id}.js`
      exit_status = $?
      content_type :json
      FileUtils.rm(output_file_name) if cleanup_file
      JSON.generate({ output: output, exit_status: exit_status })

    when 'frontend', 'experiment'
      # already written file
      content_type :json
      JSON.generate({ success: true })

    else
      status 403
      content_type :json
      JSON.generate({ error: "Invalid mode: #{mode}" })
    end
  end

  helpers do
    def store
      $store ||=
        begin
          require 'store'
          Store.instance
        end
    end
  end
end

require 'socket'
require 'timeout'
def port_available?(port, ip = '0.0.0.0')
  begin
    Timeout::timeout(0.01) do
      begin
        s = TCPSocket.new(ip, port)
        s.close
        return false
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return true
      end
    end
  rescue Timeout::Error
    return true
  end
end

def find_a_port
  loop do
    port = rand(38000..39999)
    if port_available?(port)
      return port
    end
  end
end

def expire_process(pid, user_token)
  sleep 600 # 10 minutes
  puts "TERMINATING #{pid} (expired)"
  begin
    store.del_user_pid(user_token)
    puts Process.kill "KILL", pid
  rescue Errno::ESRCH => e
    puts e.message
  end
end

def random_string
  (0...32).map { ([65,97].sample + rand(26)).chr }.join
end

