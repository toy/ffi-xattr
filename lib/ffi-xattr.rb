require 'ffi'
require 'ffi-xattr/version'
require 'ffi-xattr/error'

case RUBY_PLATFORM
when /linux/
  require 'ffi-xattr/linux_lib'
when /darwin|bsd/
  require 'ffi-xattr/darwin_lib'
else
  raise NotImplementedError, "ffi-xattr not supported on #{RUBY_PLATFORM}"
end

class Xattr
  include Enumerable

  def initialize(path, options = {})
    raise Errno::ENOENT, path unless File.exist?(path)
    @path = path
    @no_follow = !!options[:no_follow]
  end

  def list
    Lib.list @path, @no_follow
  end

  def get(key)
    Lib.get @path, @no_follow, key.to_s
  end
  alias_method :[], :get

  def set(key, value)
    Lib.set @path, @no_follow, key.to_s, value.to_s
  end
  alias_method :[]=, :set

  def remove(key)
    Lib.remove @path, @no_follow, key.to_s
  end

  def each(&blk)
    list.each do |key|
      yield key, get(key)
    end
  end

  def as_json(*args)
    res = {}
    each { |k,v| res[k] = v }

    res
  end

end
