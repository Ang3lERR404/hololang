const llib = @import("llib.zig");
const Allocat = llib.std.mem.Allocator;
const This = @This();

pub const States = enum {
  start,
  identifier,
  keyword,
  unknown,
  expression,
  comment,
  righthand,
  lefthand,
  multiline,
  mutability,
  assembly,
  EOF,
  statement,
  parameters,
  special,
  object,
  reference,
  dereference,
  string,
  number,
  array,
  newline,
  block,
  params
};

pub const Tag = enum {
  erronious, symbol, literal, eof,
  unknown, declaration, identification,
  expression, keyword, whitespace, function,
  comment, multiline, statement, block, argument,
  opening, closing
};

state:States,
tag:Tag,
region:[2]usize = [_]usize{0, 0},
lcol:[2]usize = [_]usize{0, 0},

pub fn init(state:States, tag:Tag) This {
  return This{
    .state = state,
    .tag = tag
  };
}

pub fn deinit(this:*This, cat:Allocat) void {
  cat.free(this.region);
  cat.free(this.lcol);
}

pub fn grab(this:*This, str:anytype) []u8 {
  return str[this.region[0]..this.region[1]];
}

pub fn grabZ(this:*This, str:anytype) [:0]u8 {
  return str[this.region[0]..this.region[1]:0];
}

pub fn instantiate(this:*This) void {
  this.region[0] = 0;
  this.region[1] = 0;
  this.lcol[0] = 0;
  this.lcol[1] = 0;
}