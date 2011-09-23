require 'ffi'
require 'ffi-xattr/version'

class Xattr
  module Lib
    extend FFI::Library

    ffi_lib "c"

    attach_function :strerror, [:int], :string

    attach_function :listxattr,   [:string, :pointer, :size_t], :size_t
    attach_function :setxattr,    [:string, :string, :pointer, :size_t, :int], :int
    attach_function :getxattr,    [:string, :string, :pointer, :size_t], :int
    attach_function :removexattr, [:string, :string], :int
  end

  def initialize(path)
    raise Errno::ENOENT, path unless File.exist?(path)
    @path = path
  end

  def list
    size = Lib.listxattr(@path, nil, 0)
    res_ptr = FFI::MemoryPointer.new(:pointer, size)
    Lib.listxattr(@path, res_ptr, size)

    res_ptr.read_string(size).split("\000")
  end

  def get(key)
    size = Lib.getxattr(@path, key.to_s, nil, 0)
    return unless size > 0

    str_ptr = FFI::MemoryPointer.new(:char, size);
    Lib.getxattr(@path, key.to_s, str_ptr, size)

    str_ptr.read_string
  end

  def set(key, value)
    key, value = key.to_s, value.to_s

    check_error Lib.setxattr(@path, key, value, value.bytesize, 0)
  end

  def remove(key)
    check_error Lib.removexattr(@path, key.to_s)
  end

  private

  def check_error(int)
    raise "unable to set xattr (#{Lib.strerror FFI.errno})" if int != 0
  end
end


