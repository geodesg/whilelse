require 'socket'
require 'timeout'

module PortUtil
  extend self

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
end
