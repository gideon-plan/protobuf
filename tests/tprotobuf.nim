{.experimental: "strict_funcs".}
import std/[unittest, strutils, tables]
import protobuf
suite "wire":
  test "varint round-trip":
    for v in [0'u64, 1, 127, 128, 16383, 300, 1000000]:
      let enc = encode_varint(v)
      var pos = 0
      check decode_varint(enc, pos) == v
  test "zigzag round-trip":
    for v in [0'i64, 1, -1, 100, -100, 2147483647, -2147483648]:
      check decode_zigzag(encode_zigzag(v)) == v
  test "fixed32 round-trip":
    let enc = encode_fixed32(0xDEADBEEF'u32)
    var pos = 0
    check decode_fixed32(enc, pos) == 0xDEADBEEF'u32
  test "fixed64 round-trip":
    let enc = encode_fixed64(0xCAFEBABE12345678'u64)
    var pos = 0
    check decode_fixed64(enc, pos) == 0xCAFEBABE12345678'u64
  test "bytes round-trip":
    let enc = encode_bytes("hello world")
    var pos = 0
    check decode_bytes(enc, pos) == "hello world"
  test "tag round-trip":
    let enc = encode_tag(1, wtVarint)
    var pos = 0
    let (f, w) = decode_tag(enc, pos)
    check f == 1
    check w == wtVarint
suite "parser":
  test "parse simple proto":
    let source = """
syntax = "proto3";
package test;
message Person {
  string name = 1;
  int32 age = 2;
}
"""
    let r = parse_proto(source)
    check r.is_good
    check r.val.package == "test"
    check r.val.messages.len == 1
    check r.val.messages[0].name == "Person"
    check r.val.messages[0].fields.len == 2
suite "encode/decode":
  test "message round-trip":
    let msg = ProtoMessage(name: "Test", fields: @[
      ProtoField(name: "id", number: 1, field_type: pftInt64),
      ProtoField(name: "name", number: 2, field_type: pftString)])
    var vals: Table[string, FieldValue]
    vals["id"] = FieldValue(kind: pftInt64, int_val: 42)
    vals["name"] = FieldValue(kind: pftString, str_val: "hello")
    let encoded = encode_message(msg, vals)
    let decoded = decode_message(encoded)
    check decoded.is_good
    check decoded.val.len == 2
    check decoded.val[0].field_number == 1
    check decoded.val[0].varint_val == 42
    check decoded.val[1].field_number == 2
    check decoded.val[1].bytes_val == "hello"
