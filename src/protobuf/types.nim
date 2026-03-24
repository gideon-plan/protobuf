## types.nim -- Protobuf type model.
{.experimental: "strict_funcs".}
type
  ProtoFieldType* = enum
    pftDouble, pftFloat, pftInt32, pftInt64, pftUint32, pftUint64,
    pftSint32, pftSint64, pftFixed32, pftFixed64, pftSfixed32, pftSfixed64,
    pftBool, pftString, pftBytes, pftEnum, pftMessage
  ProtoField* = object
    name*: string
    number*: int
    field_type*: ProtoFieldType
    repeated*: bool
    message_name*: string  ## For pftMessage/pftEnum
  ProtoEnum* = object
    name*: string
    values*: seq[(string, int)]
  ProtoMessage* = object
    name*: string
    fields*: seq[ProtoField]
    enums*: seq[ProtoEnum]
    nested*: seq[ProtoMessage]
  ProtoFile* = object
    syntax*: string
    package*: string
    messages*: seq[ProtoMessage]
    enums*: seq[ProtoEnum]
