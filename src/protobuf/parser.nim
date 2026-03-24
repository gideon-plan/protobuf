## parser.nim -- .proto file parser (simplified).
{.experimental: "strict_funcs".}
import std/strutils
import lattice, types
proc parse_proto*(source: string): Result[ProtoFile, BridgeError] =
  var pf: ProtoFile
  pf.syntax = "proto3"
  var current_msg: ProtoMessage
  var in_message = false
  var field_num = 0
  for line in source.splitLines():
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed.startsWith("//"): continue
    if trimmed.startsWith("syntax"):
      if trimmed.contains("proto3"): pf.syntax = "proto3"
      elif trimmed.contains("proto2"): pf.syntax = "proto2"
    elif trimmed.startsWith("package"):
      let parts = trimmed.split(" ")
      if parts.len >= 2: pf.package = parts[1].strip(chars = {';', ' '})
    elif trimmed.startsWith("message"):
      let parts = trimmed.split(" ")
      if parts.len >= 2:
        if in_message: pf.messages.add(current_msg)
        current_msg = ProtoMessage(name: parts[1].strip(chars = {'{', ' '}))
        in_message = true
        field_num = 0
    elif trimmed == "}":
      if in_message:
        pf.messages.add(current_msg)
        in_message = false
    elif in_message and trimmed.contains("="):
      let parts = trimmed.strip(chars = {';'}).splitWhitespace()
      if parts.len >= 3:
        var ft = pftString
        var repeated = false
        var idx = 0
        if parts[0] == "repeated": repeated = true; idx = 1
        let type_str = parts[idx]
        ft = case type_str
          of "double": pftDouble
          of "float": pftFloat
          of "int32": pftInt32
          of "int64": pftInt64
          of "uint32": pftUint32
          of "uint64": pftUint64
          of "sint32": pftSint32
          of "sint64": pftSint64
          of "bool": pftBool
          of "string": pftString
          of "bytes": pftBytes
          else: pftMessage
        let fname = parts[idx + 1]
        inc field_num
        var fnum = field_num
        let eq_idx = trimmed.find('=')
        if eq_idx >= 0:
          let num_str = trimmed[eq_idx + 1 ..< trimmed.len].strip(chars = {';', ' '})
          try: fnum = parseInt(num_str)
          except ValueError: discard
        current_msg.fields.add(ProtoField(name: fname, number: fnum,
                                          field_type: ft, repeated: repeated,
                                          message_name: if ft == pftMessage: type_str else: ""))
  Result[ProtoFile, BridgeError].good(pf)
