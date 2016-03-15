require 'singleton'
require 'redis'

class Store
  include Singleton

  def get_token_pid(token)
    s = redis.get "user:#{token}:pid"
    s.to_i if s && s != ""
  end

  def set_token_pid(token, pid)
    redis.set "user:#{token}:pid", pid
  end

  def del_token_pid(token)
    redis.delete "user:#{token}:pid"
  end

  def redis
    @redis ||= Redis.new
  end
end
