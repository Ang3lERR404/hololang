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

pub fn init (buffer:str) This {
  const start:usize = if (llib.sW(u8, buffer, "\xEF\xBB\xBF")) 3 else 0;
  return This{
    .buffer = buffer,
    .i = start,
    .pEToken = null
  };
}

pub const Tokens:type = llib.std.ArrayList(llib.tokares);

pub fn itr (this:*This) ?Tokens {
  var tokares:llib.tokares = .{
    .column = 0,
    .line = 0,
    .result = .{
      .tag = .EOF,
      .loc = .{
        .s = this.i,
        .e = undefined
      },
    },
    .state = .unknown
  };
  // var tokens = Tokens.init(std.heap.page_allocator);

  while (this.i < this.buffer.len) : (this.i += 1) {
    const ch = this.buffer[this.i];
    const T = @TypeOf(ch);
    const TInfo = @typeInfo(T);
    switch (ch) {
      ' ', '\t', '\r' => {
        tokares.column += 1;
        tokares.result.loc.s = this.i + 1;
      },
      '\n' => {
        tokares.column = 0;
        tokares.line += 1;
      },
      'a'...'z', 'A'...'Z', '0'...'9' => {
        tokares.column += 1;
        tokares.result = .{ .tag = .identifier };
        tokares.state = .unknown;
      },
      '@', '$' => {
        if (TInfo == .Null) continue;
      }
    }
  }
  return null;
}

test "general" {
  // language proposal 0.1?
  var tokenz = This.init(
    \\$mui<mut>:i = 51+2;
    \\@for<!mut>{expr<2>:2;stmt<1>:3} sct1:(expr); sct2:{stmt}; <{
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
    \\      int 0x10-!>
    \\  }
    \\}
    \\print($mui);
  );
  tokenz.itr();
}