const llib = @import("llib.zig");
const Allocat = llib.std.mem.Allocator;
const This = @This();
pub const Tokens = llib.std.ArrayList(This);

pub const tType = enum {
  assign,
  plus,
  minus,
  modu,
  bang,
  asterisk,
  slash,
  eq,
  noteq,
  lt,
  gt,

  tand,
  tor,
  xor,

  ident,
  int,
  string,
  typ,

  comma,
  semicolon,
  lparen,
  rparen,
  lbrackt,
  rbrackt,
  lLbow,
  rLbow,
  dividerB,
  dividerE,
  delimB,
  delimE,
  fazctB,
  fazctE,
  asmB,
  asmE,

  funct,
  variable,
  tif,
  telse,
  telseif,
  treturn,
  ttrue,
  tfalse,
  expr,
  stmt,
  sct,
  kywrd,
  mthd,
  comment,

  ill,
  err,
  eof,
  whitespace,

  Unknown
};

tokenType: tType,
literal:[]const u8,
literalChar:u8,
lineColl:[2]isize,

pub inline fn isEq(this:*This, other:tType) bool {
  return this.*.tokenType == other;
}