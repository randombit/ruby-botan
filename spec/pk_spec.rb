require 'spec_helper'

describe 'PK' do
  context 'rsa generation' do
    let(:priv) { Botan::PK::PrivateKey.generate('rsa', 1024, Botan::RNG.new) }
    let(:pub) { priv.public_key }
    let(:enc) { Botan::PK::Encrypt.new(pub, 'EME1(SHA-256)') }
    let(:dec) { Botan::PK::Decrypt.new(priv, 'EME1(SHA-256)') }
    let(:sign) { Botan::PK::Sign.new(priv, 'EMSA4(SHA-384)') }
    let(:verify) { Botan::PK::Verify.new(pub, 'EMSA4(SHA-384)') }
    let(:rng) { Botan::RNG.new }
    let(:symkey) { rng.get(32) }

    it 'has a valid fingerprint length' do
      expect(pub.fingerprint('SHA-256').length).to eql 64
    end

    it 'has a valid estimated strength' do
      expect(pub.estimated_strength).to be >= 1
    end

    it 'has the correct algorithm name' do
      expect(pub.algo_name).to eql 'RSA'
    end

    it 'can export the public key' do
      expect(pub.export(pem=true).length).to be >= 1
      expect(pub.export(pem=false).length).to be >= 1
    end

    it 'can export the private key' do
      expect(priv.export(pem=true).length).to be >= 1
      expect(priv.export(pem=false).length).to be >= 1
    end

    it 'can encrypt and decrypt' do
      ctext = enc.encrypt(symkey, rng)
      decrypted = dec.decrypt(ctext)
      expect(decrypted).to eql symkey
    end

    it 'can sign and verify' do
      sign << 'mess'
      sign << 'age'
      signature = sign.finish(rng)

      verify << 'mes'
      verify << 'sage'
      expect(verify.check_signature(signature)).to eql true

      verify << 'mess of things'
      verify << 'age'
      expect(verify.check_signature(signature)).to eql false

      verify << 'message'
      expect(verify.check_signature(signature)).to eql true
    end
  end

  context 'ecdsa generation' do
    let(:priv) { Botan::PK::PrivateKey.generate('ecdsa', 'secp384r1', Botan::RNG.new) }
    let(:pub) { priv.public_key }
    let(:sign) { Botan::PK::Sign.new(priv, 'EMSA1(SHA-384)') }
    let(:verify) { Botan::PK::Verify.new(pub, 'EMSA1(SHA-384)') }
    let(:rng) { Botan::RNG.new }
    let(:symkey) { rng.get(32) }

    it 'has a valid fingerprint length' do
      expect(pub.fingerprint('SHA-256').length).to eql 64
    end

    it 'has a valid estimated strength' do
      expect(pub.estimated_strength).to be >= 1
    end

    it 'has the correct algorithm name' do
      expect(pub.algo_name).to eql 'ECDSA'
    end

    it 'can export the public key' do
      expect(pub.export(pem=true).length).to be >= 1
      expect(pub.export(pem=false).length).to be >= 1
    end

    it 'can export the private key' do
      expect(priv.export(pem=true).length).to be >= 1
      expect(priv.export(pem=false).length).to be >= 1
    end

    it 'can sign and verify' do
      sign << 'mess'
      sign << 'age'
      signature = sign.finish(rng)

      verify << 'mes'
      verify << 'sage'
      expect(verify.check_signature(signature)).to eql true

      verify << 'mess of things'
      verify << 'age'
      expect(verify.check_signature(signature)).to eql false

      verify << 'message'
      expect(verify.check_signature(signature)).to eql true
    end
  end

  context 'ecdh generation' do
    let(:a_rng) { Botan::RNG.new('user') }
    let(:b_rng) { Botan::RNG.new('user') }
    let(:dh_kdf) { 'KDF2(SHA-384)' }
    let(:group) { 'secp256r1' }
    let(:a_dh_priv) { Botan::PK::PrivateKey.generate('ecdh', group, Botan::RNG.new) }
    let(:b_dh_priv) { Botan::PK::PrivateKey.generate('ecdh', group, Botan::RNG.new) }
    let(:a_dh) { Botan::PK::KeyAgreement.new(a_dh_priv, dh_kdf) }
    let(:b_dh) { Botan::PK::KeyAgreement.new(b_dh_priv, dh_kdf) }
    let(:a_dh_pub) { a_dh.public_value }
    let(:b_dh_pub) { b_dh.public_value }
    let(:a_salt) { a_rng.get(8) }
    let(:b_salt) { b_rng.get(8) }

    it 'key agreement' do
      a_key = a_dh.agree(b_dh_pub, 32, a_salt + b_salt)
      b_key = b_dh.agree(a_dh_pub, 32, a_salt + b_salt)
      expect(a_key).to eql b_key
    end
  end

  context Botan::PK::PrivateKey.method(:generate) do
    it 'errors on invalid algorithm' do
      expect{
        Botan::PK::PrivateKey.generate('fake', nil, Botan::RNG.new)
      }.to raise_error(Botan::Error)
    end
  end

  context Botan::PK::PrivateKey.method(:load) do
    let(:private_key_pem) { File.read('spec/data/private_key.pem') }
    let(:key) { Botan::PK::PrivateKey.load(private_key_pem, Botan::RNG.new, '') }

    it 'exports correctly' do
      expect(key.export(pem=true)).to eql private_key_pem
    end
  end

  context Botan::PK::PublicKey.method(:load) do
    let(:public_key_pem) { File.read('spec/data/public_key.pem') }
    let(:key) { Botan::PK::PublicKey.load(public_key_pem) }

    it 'exports correctly' do
      expect(key.export(pem=true)).to eql public_key_pem
    end
  end
end

