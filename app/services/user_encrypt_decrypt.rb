require 'openssl'
require 'base64'

class UserEncryptDecrypt
  def self.included(base)
    base.extend self
  end

  def cipher
    # OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    # OpenSSL::Cipher.new('aes-256-cbc')
    OpenSSL::Cipher.new('AES-256-CBC')
  end

  def cipher_key
    'blah!'
  end

  def decrypt(value)
    c = cipher.decrypt
    c.key = Digest::SHA256.digest(cipher_key)
    c.update(Base64.decode64(value.to_s)) + c.final
  end

  def encrypt(value)
    c = cipher.encrypt
    c.key = Digest::SHA256.digest(cipher_key)
    Base64.encode64(c.update(value.to_s) + c.final)
  end
end