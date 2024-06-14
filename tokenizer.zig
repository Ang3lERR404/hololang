const llib = @import("llib.zig");
const std = llib.std;
const This = @This();
const str:type = [:0]const u8;

/// a string, or "buffer" if you will.
buffer:str,
/// Index
i:usize,
/// Pending Erronious Token
pEToken:?llib.token,

pub fn dump(this:*This, token:*const llib.token) void {
  llib.print("{s}: '{s}'\n", .{
    @tagName(token.tag),
    this.buffer[token.loc.s..token.loc.e]
  });
}

pub fn init (buffer:str) This {
  const start:usize = if (llib.sW(u8, buffer, "\xEF\xBB\xBF")) 3 else 0;
  return This{
    .buffer = buffer,
    .i = start,
    .pEToken = null
  };
}

pub fn itr (this:*This) void {
  while (this.i < this.buffer.len) : (this.i+=1) {
    const c = this.buffer[this.i];
    switch (c) {
      else => {
        if (this.i % 10 == 9) {
          llib.print("\n", .{});
          continue;
        }
        llib.print("{any} = '{c}' ", .{c, c});
      }
    }
  }
}

test "general" {
  // language proposal 0.1?
  var tokenz = This.init(
    \\$mui<mut>:unknown = 51+2;
    \\@"for"<!mut>{expr<2>:2;stmt<1>:3} sct1:(expr); sct2:{stmt}; <{
    \\  ~`!@#$%^&*()-_=+123456789
    \\}>
    \\@print<!mut> ($zesh<mut>:anytype) {
    \\  $zesh = <:-codes-:>;
    \\  $i<mut>:usize = 0;
    \\  for ($i < $zesh.len) {
    \\    $code = $zesh[i];
    \\    <!-
    \\      mov ah, 0x0E
    \\      mov al, <!>code
    \\      int 0x10
    \\  -!>}
    \\}
    \\print($mui);
  );
  tokenz.itr();
}