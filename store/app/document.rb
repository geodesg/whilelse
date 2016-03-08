class Document
  attr_accessor :name

  def initialize(name)
    self.name = name
  end

  def self.commands(document_name, &proc)
    commands = []
    each_command(document_name) do |command|
      if command[0] == 'undo'
        commands.pop(command[1]['val'] || 1)
      else
        commands << command
      end
    end
    commands
  end

  def self.each_command(document_name, state = nil, &proc)
    state ||= { loaded: {} }
    return if state[:loaded][document_name]
    state[:loaded][document_name] = true
    File.open fn(document_name) do |f|
      f.each_line do |line|
        command = JSON.parse(line.strip)
        if command[0] == 'dep'
          each_command(command[1]['name'], state, &proc)
        else
          proc.(command)
        end
      end
    end
  end

  def self.fn(document_name)
    APP_PATH.join('data', 'documents', "#{document_name}.dylog")
  end
end
