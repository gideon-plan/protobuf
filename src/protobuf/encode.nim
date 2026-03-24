## encode.nim -- Generic message encoder.
{.experimental: "strict_funcs".}
import std/tables
import lattice, wire, types
type FieldValue* = object
  case kind*: ProtoFieldType
  of pftInt32, pftInt64, pftUint32, pftUint64, pftSint32, pftSint64, pftEnum:
    int_val*: int64
  of pftDouble:
    double_val*: float64
  of pftFloat:
    float_val*: float32
  of pftBool:
    bool_val*: bool
  of pftString, pftBytes:
    str_val*: string
  of pftFixed32, pftSfixed32:
    fixed32_val*: uint32
  of pftFixed64, pftSfixed64:
    fixed64_val*: uint64
  of pftMessage:
    msg_val*: string  ## Pre-encoded nested message
proc encode_field*(field: ProtoField, value: FieldValue): string =
  case value.kind
  of pftInt32, pftInt64, pftUint32, pftUint64, pftEnum:
    encode_tag(field.number, wtVarint) & encode_varint(uint64(value.int_val))
  of pftSint32, pftSint64:
    encode_tag(field.number, wtVarint) & encode_varint(encode_zigzag(value.int_val))
  of pftBool:
    encode_tag(field.number, wtVarint) & encode_varint(if value.bool_val: 1'u64 else: 0'u64)
  of pftString, pftBytes:
    encode_tag(field.number, wtLengthDelimited) & encode_bytes(value.str_val)
  of pftDouble:
    encode_tag(field.number, wt64Bit) & encode_fixed64(cast[uint64](value.double_val))
  of pftFloat:
    encode_tag(field.number, wt32Bit) & encode_fixed32(cast[uint32](value.float_val))
  of pftFixed32, pftSfixed32:
    encode_tag(field.number, wt32Bit) & encode_fixed32(value.fixed32_val)
  of pftFixed64, pftSfixed64:
    encode_tag(field.number, wt64Bit) & encode_fixed64(value.fixed64_val)
  of pftMessage:
    encode_tag(field.number, wtLengthDelimited) & encode_bytes(value.msg_val)
proc encode_message*(msg: ProtoMessage, values: Table[string, FieldValue]): string =
  for f in msg.fields:
    if f.name in values:
      result.add(encode_field(f, values[f.name]))
