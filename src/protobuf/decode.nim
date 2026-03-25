## decode.nim -- Generic message decoder.
{.experimental: "strict_funcs".}

import basis/code/choice, wire
type DecodedField* = object
  field_number*: int
  wire_type*: WireType
  varint_val*: uint64
  bytes_val*: string
  fixed32_val*: uint32
  fixed64_val*: uint64
proc decode_message*(buf: string): Choice[seq[DecodedField]] =
  var pos = 0
  var fields: seq[DecodedField]
  while pos < buf.len:
    let (fnum, wt) = decode_tag(buf, pos)
    var df = DecodedField(field_number: fnum, wire_type: wt)
    case wt
    of wtVarint: df.varint_val = decode_varint(buf, pos)
    of wt64Bit: df.fixed64_val = decode_fixed64(buf, pos)
    of wtLengthDelimited: df.bytes_val = decode_bytes(buf, pos)
    of wt32Bit: df.fixed32_val = decode_fixed32(buf, pos)
    fields.add(df)
  good(fields)
