#!/usr/bin/env python3
"""
aes128_sim.py

Simulate AES-128 encryption of a single 16-byte block using a constant key.
"""

from Crypto.Cipher import AES

def aes128_encrypt_block(plaintext_block: bytes, key: bytes) -> bytes:
    cipher = AES.new(key, AES.MODE_ECB)
    return cipher.encrypt(plaintext_block)

def aes128_decrypt_block(cipher_text_block: bytes, key: bytes) -> bytes:
    plain = AES.new(key, AES.MODE_ECB)
    return plain.decrypt(cipher_text_block)

def main():
    # 128-bit (16-byte) constant key
    key = bytes.fromhex('2b7e151628aed2a6abf7158809cf4f3c')
    # 128-bit plaintext block
    plaintext = bytes.fromhex('00112233445566778899aabbccddeeff')

    ciphertext = aes128_encrypt_block(plaintext, key)
    plaintext_recon = aes128_decrypt_block(ciphertext, key)
    
    print("Key              :", key.hex())
    print("Plain text       :", plaintext.hex())
    print("Cipher text      :", ciphertext.hex())
    print("plain_recon text :", plaintext_recon.hex())
    
if __name__ == "__main__":
    main()
