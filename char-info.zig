const llib = @import("llib.zig");
const std = llib.std;
const This = @This();

literal:u8,
typeX:type,
typeInfo:std.builtin.Type,

pub fn init(literal:u8) This {
  const T:type = @TypeOf(literal);
  return This{
    .literal = literal,
    .typeX = T,
    .typeInfo = @typeInfo(T) 
  };
}

pub fn isNull (this:*This) bool {
  return this.typeInfo == .Null;
}