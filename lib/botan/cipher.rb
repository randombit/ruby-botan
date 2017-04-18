module Botan
  class Cipher
    def initialize(algo, encrypt=true)
      flags = encrypt ? 0 : 1
      cipher_ptr = FFI::MemoryPointer.new(:pointer)
      rc = LibBotan.botan_cipher_init(cipher_ptr, algo, flags)
      raise if rc != 0
      @ptr = cipher_ptr.read_pointer
      raise if @ptr.null?
      @ptr_auto = FFI::AutoPointer.new(@ptr, self.class.method(:destroy))
    end

    def self.destroy(ptr)
      LibBotan.botan_cipher_destroy(ptr)
    end

    def default_nonce_length
      length_ptr = FFI::MemoryPointer.new(:size_t)
      rc = LibBotan.botan_cipher_get_default_nonce_length(@ptr, length_ptr)
      raise if rc != 0
      length_ptr.read(:size_t)
    end

    def update_granularity
      gran_ptr = FFI::MemoryPointer.new(:size_t)
      rc = LibBotan.botan_cipher_get_update_granularity(@ptr, gran_ptr)
      raise if rc != 0
      gran_ptr.read(:size_t)
    end

    def key_length
      kmin_ptr = FFI::MemoryPointer.new(:size_t)
      kmax_ptr = FFI::MemoryPointer.new(:size_t)
      rc = LibBotan.botan_cipher_query_keylen(@ptr, kmin_ptr, kmax_ptr)
      raise if rc != 0
      return [kmin_ptr.read(:size_t), kmax_ptr.read(:size_t)]
    end

    def tag_length
      length_ptr = FFI::MemoryPointer.new(:size_t)
      rc = LibBotan.botan_cipher_get_tag_length(@ptr, length_ptr)
      raise if rc != 0
      length_ptr.read(:size_t)
    end

    def authenticated?
      tag_length > 0
    end

    def valid_nonce_length?(nonce_len)
      rc = LibBotan.botan_cipher_valid_nonce_length(@ptr, nonce_len)
      raise if rc < 0
      return (rc == 1) ? true : false
    end

    def clear
      rc = LibBotan.botan_cipher_clear(@ptr)
      raise if rc != 0
    end

    def set_key(key)
      key_buf = FFI::MemoryPointer.new(:uint8, key.bytesize)
      key_buf.write_bytes(key)
      rc = LibBotan.botan_cipher_set_key(@ptr, key_buf, key_buf.size)
      raise if rc != 0
    end

    def set_assoc_data(ad)
      ad_buf = FFI::MemoryPointer.new(:uint8, ad.bytesize)
      ad_buf.write_bytes(ad)
      rc = LibBotan.botan_cipher_set_associated_data(@ptr, ad_buf, ad.size)
      raise if rc != 0
    end

    def start(nonce)
      nonce_buf = FFI::MemoryPointer.new(:uint8, nonce.bytesize)
      rc = LibBotan.botan_cipher_start(@ptr, nonce_buf, nonce_buf.size)
      raise if rc != 0
    end

    def _update(txt, final)
      inp = txt ? txt : ''
      flags = final ? 1 : 0
      out_buf = FFI::MemoryPointer.new(:uint8, inp.bytesize + (final ? tag_length() : 0))
      out_written_ptr = FFI::MemoryPointer.new(:size_t)
      input_buf = FFI::MemoryPointer.new(:uint8, inp.bytesize)
      input_buf.write_bytes(inp)
      inp_consumed_ptr = FFI::MemoryPointer.new(:size_t)
      rc = LibBotan.botan_cipher_update(@ptr, flags, out_buf, out_buf.size,
                                         out_written_ptr, input_buf, input_buf.size,
                                         inp_consumed_ptr)
      raise if rc != 0
      raise if inp_consumed_ptr.read(:size_t) != inp.bytesize
      out_buf.read_bytes(out_written_ptr.read(:size_t))
    end

    def update(txt)
      _update(txt, false)
    end

    def finish(txt=nil)
      _update(txt, true)
    end
  end # class
end # module

