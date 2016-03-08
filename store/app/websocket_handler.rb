require 'hashie'

class WebsocketHandler
  attr_reader :ws, :channel_registry

  def initialize(ws, channel_registry)
    @ws = ws
    @channel_registry = channel_registry
  end

  def run
    @ws.on :open do |event|
      with_rescue do
        puts "OPENED"
      end
    end
    @ws.on :message do |event|
      with_rescue do
        puts "RECEIVED: #{event.data}"
        handle_message(Hashie::Mash.new(JSON.parse(event.data)))
      end
    end

    @ws.on :close do |event|
      with_rescue do
        p ["CLOSED", event.code, event.reason]
        @ws = nil
      end
    end

    ws.rack_response
  end


  def with_rescue
    yield
  rescue => e
    puts "ERROR: #{e.class}: #{e.message}"
    puts e.backtrace
  end

  def handle_message(message)
    case message.type
    when 'init'
      # TODO: open a document
      self.document_name = message.document
    when 'all' # Send all command in a document and all dependent documents
      if !document_name
        send_message(type: 'error', message: "No document selected. Can't process 'all'.")
      else
        state = { loaded: {} }
        commands = []
        each_commands_from_document(document_name, state) do |command|
          if command[0] == 'undo'
            commands.pop(command[1]['val'] || 1)
          else
            commands << command
          end
        end
        commands.each do |command|
          send_message(type: 'command', data: command)
        end

        send_message(type: 'done')
      end
    when 'command' # Save command sent by the front-end
      if !document_name
        send_message(type: 'error', message: "No document selected. Can't process 'command'.")
      else
        File.open(document_fn, 'a') do |f|
          f.puts JSON.generate message.data
        end
      end
    when 'pad'
    else
      puts "ERROR: Unknown message type: #{message.type}"
    end
  end

  def send_message(message)
    @ws.send(JSON.generate(message))
  end

  private
  attr_accessor :document_name

  def history_fn
    APP_PATH.join('data', 'history.dylog')
  end

  def document_fn
    raise "No document selected" if !document_name
    APP_PATH.join('data', 'documents', "#{document_name}.dylog")
  end

  def fn(document_name)
    APP_PATH.join('data', 'documents', "#{document_name}.dylog")
  end

  def each_commands_from_document(document_name, state, &proc)
    return if state[:loaded][document_name]
    state[:loaded][document_name] = true
    File.open fn(document_name) do |f|
      f.each_line do |line|
        command = JSON.parse(line.strip)
        if command[0] == 'dep'
          each_commands_from_document(command[1]['name'], state, &proc)
        else
          proc.(command)
        end
      end
    end
  end
end
