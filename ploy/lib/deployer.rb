require 'port_util'

class Deployer

  attr_accessor :params
  attr_reader :result

  def initialize(params)
    self.params = params
  end

  def run
    mode = params['mode']
    # mode:
    #   default: 'service' - deploy a long-running service, takes a port as an argument
    #   'run' - run an app that should execute quickly, wait for exit and return output
    #   'frontend' - place file in frontend/app/generated/

    cleanup_file = false

    contents = params['contents']
    user_token = params['user_token'] || random_string
    user_app_token = "#{user_token}#{params['app_id']}"
    id = user_app_token
    if mode == 'frontend'
      frontend_root = APP_ROOT.join('..', 'frontend', 'app', 'generated')
      raise "Invalid path: #{params['name']}" if ! Validator.valid_subpath?(params['name'])
      output_file_name = frontend_root.join(params['name']).to_s
    elsif mode == 'experiment'
      raise "Invalid file name: #{params['name']}" if ! Validator.valid_filename?(params['name'])
      experiment_root = APP_ROOT.join('..', 'tmp', 'experiments')
      output_file_name = experiment_root.join(params['name']).to_s
    else
      content_root = APP_ROOT.join('contents')
      cleanup_file = true
      output_file_name = content_root.join("app#{id}.js")
    end
    FileUtils.mkdir_p(File.dirname(output_file_name))
    puts "-" * 50
    puts "WRITING #{id} - Writing to #{output_file_name}"
    puts contents
    puts
    File.open(output_file_name, 'w') do |f|
      f.write(contents)
    end

    case mode
    when 'service', nil
      # Kill user's current app, if any
      pid = store.get_token_pid(user_app_token)
      if pid
        puts "TERMINATING #{pid}"
        begin
          puts Process.kill "KILL", pid
        rescue Errno::ESRCH => e
          puts e.message
        end
      end

      port = PortUtil.find_a_port

      # Start new app
      pid = fork do
        Dir.chdir content_root.to_s
        puts "CHILD on port #{port}"
        exec "node app#{id}.js #{port}"
      end
      # TODO: clean up file when process terminates
      store.set_token_pid(user_app_token, pid)
      puts "FORKED #{pid}"

      Thread.new(pid, user_app_token, &method(:expire_process))

      @result = { success: true, url: "#{ENV['DEPLOY_PROTOCOL']}//#{ENV['DEPLOY_HOSTNAME']}:#{port}/" }

    when 'run'
      Dir.chdir content_root.to_s
      puts "-" * 50
      puts "RUNNING #{id}"
      output = `node app#{id}.js`
      puts "-" * 50
      puts "OUTPUT #{id}"
      puts output
      exit_status = $?
      FileUtils.rm(output_file_name) if cleanup_file
      @result = { success: true, output: output, exit_status: exit_status }

    when 'frontend', 'experiment'
      # already written file
      @result = { success: true }

    else
      @result = { error: "Invalid mode: #{mode}" }
    end
    @result
  end

  def store
    $store ||=
      begin
        require 'store'
        Store.instance
      end
  end


  def expire_process(pid, user_app_token)
    sleep 600 # 10 minutes
    puts "TERMINATING #{pid} (expired)"
    begin
      store.del_token_pid(user_app_token)
      puts Process.kill "KILL", pid
    rescue Errno::ESRCH => e
      puts e.message
    end
  end

  def random_string
    (0...32).map { ([65,97].sample + rand(26)).chr }.join
  end

end
