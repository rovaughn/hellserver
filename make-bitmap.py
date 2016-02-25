#!/usr/bin/python3
import sys

def make_bitfield(bytes):
    nums = []

    for byte in bytes:
        num = 0

        for i, bit in enumerate(byte):
            num |= bit << i

        nums.append(num)

    return ','.join('0h%02x' % num for num in nums)

def group8(bits):
    if len(bits) % 8 != 0:
        raise ValueError('Bit field should have multiple of 8 bits')

    nums = []

    for i in range(0, len(bits), 8):
        num = 0

        for i, bit in enumerate(bits[i:i+8]):
            num |= bit << i

        nums.append(num)

    return nums

bits = []

for ch in range(0, 127-32+1):
    if ch+32 < 127 and chr(ch+32) not in "()<>@,;:\\\"/[]?={} \t":
        bits.append(1)
    else:
        bits.append(0)

bytes = group8(bits)

def check_character(ch):
    b = ord(ch) - 32

    return ((bytes[b >> 3] >> (b & 0x07)) & 0x01) == 1

for ch in range(32, 128):
    is_token_char = check_character(chr(ch))

    if is_token_char and chr(ch) in "()<>@,;:\\\"/[]?={} \t":
        print('misclassified', ch)

