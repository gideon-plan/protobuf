## wire.nim -- Protobuf wire format encode/decode.
{.experimental: "strict_funcs".}
import lattice
type
  WireType* = enum
    wtVarint = 0, wt64Bit = 1, wtLengthDelimited = 2, wt32Bit = 5
proc encode_varint*(value: uint64): string =
  var v = value
  result = ""
  while true:
    var b = uint8(v and 0x7F)
    v = v shr 7
    if v > 0: b = b or 0x80
    result.add(char(b))
    if v == 0: break
proc decode_varint*(buf: string, pos: var int): uint64 {.raises: [BridgeError].} =
  var shift = 0
  result = 0
  for i in 0 ..< 10:
    if pos >= buf.len: raise newException(BridgeError, "varint: unexpected end")
    let b = uint8(buf[pos]); inc pos
    result = result or (uint64(b and 0x7F) shl shift)
    if (b and 0x80) == 0: return
    shift += 7
  raise newException(BridgeError, "varint: too long")
proc encode_zigzag*(value: int64): uint64 =
  if value >= 0: uint64(value) shl 1
  else: (uint64(-value - 1) shl 1) or 1
proc decode_zigzag*(value: uint64): int64 =
  if (value and 1) == 0: int64(value shr 1)
  else: -int64((value shr 1) + 1)
proc encode_tag*(field_number: int, wire_type: WireType): string =
  encode_varint(uint64(field_number shl 3 or int(wire_type)))
proc decode_tag*(buf: string, pos: var int): tuple[field: int, wire: WireType] {.raises: [BridgeError].} =
  let v = decode_varint(buf, pos)
  result.field = int(v shr 3)
  result.wire = WireType(v and 0x07)
proc encode_fixed32*(value: uint32): string =
  result = newString(4)
  for i in 0 ..< 4: result[i] = char((value shr (i * 8)) and 0xFF)
proc decode_fixed32*(buf: string, pos: var int): uint32 {.raises: [BridgeError].} =
  if pos + 4 > buf.len: raise newException(BridgeError, "fixed32: too short")
  for i in 0 ..< 4: result = result or (uint32(uint8(buf[pos + i])) shl (i * 8))
  pos += 4
proc encode_fixed64*(value: uint64): string =
  result = newString(8)
  for i in 0 ..< 8: result[i] = char((value shr (i * 8)) and 0xFF)
proc decode_fixed64*(buf: string, pos: var int): uint64 {.raises: [BridgeError].} =
  if pos + 8 > buf.len: raise newException(BridgeError, "fixed64: too short")
  for i in 0 ..< 8: result = result or (uint64(uint8(buf[pos + i])) shl (i * 8))
  pos += 8
proc encode_bytes*(data: string): string =
  encode_varint(uint64(data.len)) & data
proc decode_bytes*(buf: string, pos: var int): string {.raises: [BridgeError].} =
  let length = int(decode_varint(buf, pos))
  if pos + length > buf.len: raise newException(BridgeError, "bytes: too short")
  result = buf[pos ..< pos + length]; pos += length
