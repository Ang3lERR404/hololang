const llib = @import("llib.zig");
const std = llib.std;
const str:type = [:0]const u8;
const print = llib.print;

const Tokares = llib.tokares;

pub const Tokens:type = std.ArrayList(Tokares);

pub fn itr (buff:str, cat:std.mem.Allocator) !?Tokens {
  @setEvalBranchQuota(10000);
  var res:Tokares = .{
    .state = .start,
    .tag = .unknown,
    .region = try cat.alloc(usize, 2),
    .lcol = try cat.alloc(usize, 2),
  };
  defer {
    cat.free(res.region);
    cat.free(res.lcol);
  }

  res.region[0] = 0; res.region[1] = 0;
  res.lcol[0] = 0; res.lcol[1] = 0;

  var i:usize = if (std.mem.startsWith(u8, buff, "\xEF\xBB\xBF")) 3 else 0;
  var tokens = Tokens.init(cat);
  defer tokens.deinit();

  while (i < buff.len) : (i += 1) {
    const ch = buff[i];

    switch (ch) {
      ' ', '\t', '\r' => {
        res.lcol[0] += 1;
        res.region[0] = i + 1;
      }, '\n' => {
        res.lcol[0] = 0;
        res.lcol[1] += 1;
        res.region[0] = i + 1;
        res.state = .newline;

        try tokens.append(res);
      }, else => {
        if (i % 9 == 8) print("\n", .{});
        res.lcol[0] += 1;
        print("'{c}' = {any}, ", .{ch, ch});
      }
    }

    if (i == buff.len - 1) {
      res.state = .EOF;
      try tokens.append(res);
      break;
    }
  }

  print("{any}", .{try tokens.toOwnedSlice()});

  return null;
}

test "general" {
  const pageCat = std.heap.page_allocator;
  // language proposal 0.1?
  _ = try itr(
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
  , pageCat);
}