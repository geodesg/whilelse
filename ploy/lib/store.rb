require 'singleton'
require 'redis'

class Store
  include Singleton

  def get_user_pid(user_token)
    s = redis.get "user:#{user_token}:pid"
    s.to_i if s && s != ""
  end

  def set_user_pid(user_token, pid)
    redis.set "user:#{user_token}:pid", pid
  end

  def del_user_pid(user_token)
    redis.delete "user:#{user_token}:pid"
  end

  def redis
    @redis ||= Redis.new
  end
end
