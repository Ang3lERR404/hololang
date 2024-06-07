inline fn Tiki(comptime T:type) type {
  return struct{
    pub const types = enum {whitespace, literal, symbol, unknown};
    pub const subTypes = enum {char, number, newline, unknown};
    const thi = @This();
    type:types,
    subType:subTypes,
    content:?T,

    fn init(typ:types, subType:subTypes, content:?T) thi {
      return thi{
        .type = typ,
        .subType = subType,
        .content = content orelse null
      };
    }
  };
}