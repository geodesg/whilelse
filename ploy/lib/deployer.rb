require 'port_util'

class Deployer

  attr_accessor :params
  attr_reader :result

  def initialize(params)
    self.params = params
  end

  def run
    catch :finish do
      run_inner
    end
  end

  def err(msg)
    throw :finish, { error: msg }
  end

  # mode:
  #   default: 'service' - deploy a long-running service, takes a port as an argument
  #   'run' - run an app that should execute quickly, wait for exit and return output
  #   'frontend' - place file in frontend/app/generated/
  def mode
    params['mode']
  end

  def contents
    params['contents']
  end

  def user_token
    params['user_token'] || random_string
  end

  def app_type
    params['app_type']
  end

  def user_app_token
    "#{user_token}#{params['app_id']}"
  end

  def persistent
    ['true', '1'].include? params['persistent']
  end

  def frontend_root
    APP_ROOT.join('..', 'frontend', 'app', 'generated')
  end

  def experiment_root
    APP_ROOT.join('..', 'tmp', 'experiments')
  end

  def output_file_name
    if mode == 'frontend'
      err "Invalid path: #{params['name']}" if ! Validator.valid_subpath?(params['name'])
      frontend_root.join(params['name']).to_s
    elsif mode == 'experiment'
      err "Invalid file name: #{params['name']}" if ! Validator.valid_filename?(params['name'])
      experiment_root.join(params['name']).to_s
    else
      target_root.join(output_file_relative_path)
    end
  end

  # Directory to which the application is deployed
  def target_root
    APP_ROOT.join("deployments/#{target_id}")
  end

  # Output file relative to the target_root
  def output_file_relative_path
    case app_type
    when 'react' then 'src/App.js'
    else "app.js"
    end
  end

  def process_command(port)
    case app_type
    when 'react' then "node server.js #{port}"
    else "node #{output_file_relative_path} #{port}"
    end
  end

  # Unique ID of a deployment target - must be a valid filename
  def target_id
    user_app_token
  end

  def cleanup_file?
    ['frontend', 'experiment'].include? mode
  end

  def run_inner

    prepare_boilerplate

    write_files

    case mode
    when 'service', nil
      if @already_running
        { success: true, was_already_running: true }
      else
        deploy_service
      end

    when 'run'
      run_script

    when 'frontend', 'experiment'
      # already written file
      { success: true }

    else
      { error: "Invalid mode: #{mode}" }
    end
  end

  def prepare_boilerplate
    case app_type
    when 'react'
      if ! persistent || ! File.exists?(target_root)
        FileUtils.cp_r(APP_ROOT.join('boilerplates', 'react'), target_root)
        # symlink to node_modules - copying would take about a minute
        FileUtils.ln_s(APP_ROOT.join('boilerplates', 'node_modules'), target_root.join('node_modules'))
      else
        # FIXME assuming it's running if the directory is there
        @already_running = true
      end
    else
      FileUtils.mkdir_p(File.dirname(output_file_name))
    end
  end

  def write_files
    puts "-" * 50
    puts "WRITING #{target_id} - Writing to #{output_file_name}"
    puts contents
    puts
    File.open(output_file_name, 'w') do |f|
      f.write(contents)
    end
  end

  def deploy_service
    terminate_running_process

    port = PortUtil.find_a_port

    # Start new app
    pid = fork do
      Dir.chdir target_root
      puts "CHILD on port #{port}"
      exec process_command(port)
    end
    # TODO: clean up file when process terminates
    store.set_token_pid(user_app_token, pid)
    puts "FORKED #{pid}"

    Thread.new(pid, user_app_token, &method(:expire_process))

    { success: true, url: "#{ENV['DEPLOY_PROTOCOL']}//#{ENV['DEPLOY_HOSTNAME']}:#{port}/" }
  end

  def run_script
    Dir.chdir target_root.to_s
    puts "-" * 50
    puts "RUNNING #{target_id}"
    output = `node #{output_file_relative_path}`
    puts "-" * 50
    puts "OUTPUT #{target_id}"
    puts output
    exit_status = $?
    FileUtils.rm(output_file_name)
    { success: true, output: output, exit_status: exit_status }
  end

  def terminate_running_process
    pid = store.get_token_pid(user_app_token)
    if pid
      puts "TERMINATING #{pid}"
      begin
        puts Process.kill "KILL", pid
      rescue Errno::ESRCH => e
        puts e.message
      end
    end
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
