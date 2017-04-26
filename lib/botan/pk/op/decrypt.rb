module Botan
  module PK
    class Decrypt
      def initialize(key, padding)
        ptr = FFI::MemoryPointer.new(:pointer)
        flags = 0
        rc = LibBotan.botan_pk_op_decrypt_create(ptr, key.ptr, padding, flags)
        raise if rc != 0
        @ptr = ptr.read_pointer
        raise if @ptr.null?
        @ptr_auto = FFI::AutoPointer.new(@ptr, self.class.method(:destroy))
      end

      def self.destroy(ptr)
        LibBotan.botan_pk_op_decrypt_destroy(ptr)
      end

      def decrypt(msg)
        msg_buf = FFI::MemoryPointer.new(:uint8, msg.bytesize)
        msg_buf.write_bytes(msg)
        Botan.call_ffi_returning_vec(4096, lambda {|b, bl|
          LibBotan.botan_pk_op_decrypt(@ptr, b, bl, msg_buf, msg_buf.size)
        })
      end
    end # class
  end # module
end # module

