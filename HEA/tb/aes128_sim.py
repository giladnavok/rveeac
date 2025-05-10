#!/usr/bin/env python3
"""
aes128_sim.py

Simulate AES-128 encryption of a single 16-byte block using a constant key.
"""

from Crypto.Cipher import AES

def aes128_encrypt_block(plaintext_block: bytes, key: bytes) -> bytes:
    """
    Encrypts a single 16-byte block with AES-128 in ECB mode.
    """
    if len(plaintext_block) != 16:
        raise ValueError("Plaintext must be exactly 16 bytes")
    if len(key) != 16:
        raise ValueError("Key must be exactly 16 bytes")

    cipher = AES.new(key, AES.MODE_ECB)
    return cipher.encrypt(plaintext_block)

def main():
    # 128-bit (16-byte) constant key
    key = bytes.fromhex('000102030405060708090a0b0c0d0e0f')
    # 128-bit plaintext block
    plaintext = bytes.fromhex('00112233445566778899aabbccddeeff')

    ciphertext = aes128_encrypt_block(plaintext, key)

    print("Key        :", key.hex())
    print("Plaintext  :", plaintext.hex())
    print("Ciphertext :", ciphertext.hex())

if __name__ == "__main__":
    main()
