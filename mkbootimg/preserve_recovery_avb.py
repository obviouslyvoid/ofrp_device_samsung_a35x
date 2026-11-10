#!/usr/bin/env python3
"""Relocate the exact embedded AVB block from this phone's working recovery.

This does not create or flash the separate vbmeta partition. The baseline AVB
block intentionally remains byte-identical, including its verification result.
It keeps the recovery image accepted by this device's bootloader.
"""
import argparse
import hashlib
from pathlib import Path
import struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--image', required=True, type=Path)
parser.add_argument('--metadata', required=True, type=Path)
parser.add_argument('--partition-size', required=True, type=int)
args = parser.parse_args()
metadata = args.metadata.read_bytes()
assert hashlib.sha256(metadata).hexdigest() == '7526d431df8d778c23c9633d90570eadf1f12f128d8c4b7ac41ed5aea4b2fb98', 'Wrong baseline recovery metadata'
assert len(metadata) == 2112 and metadata[:4] == b'AVB0'
image = args.image.read_bytes()
if image[-64:-60] == b'AVBf':
    _, _, _, original_size, _, _, _ = struct.unpack('!4sIIQQQ28s', image[-64:])
    assert original_size < len(image) - 64
    image = image[:original_size]
assert image[:8] == b'ANDROID!' and image.endswith(b'SEANDROIDENFORCE')
assert args.partition_size == 100663296, 'Unexpected recovery partition size'
offset = (len(image) + 4095) // 4096 * 4096
assert offset + len(metadata) <= args.partition_size - 4096, 'Recovery does not fit'
footer = struct.pack('!4sIIQQQ28s', b'AVBf', 1, 0, len(image), offset, len(metadata), bytes(28))
result = image + bytes(offset - len(image)) + metadata
result += bytes(args.partition_size - 64 - len(result)) + footer
assert len(result) == args.partition_size
temporary = args.image.with_name(args.image.name + '.avbtmp')
temporary.write_bytes(result)
temporary.replace(args.image)
print('Preserved baseline recovery AVB metadata; relocated footer to the full 96 MiB partition.')
