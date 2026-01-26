const llib = @import("llib.zig");
const std = llib.std;
const dbg = std.debug;
const print = llib.print;
const panic = dbg.panic;
const Arrlist = std.ArrayList;
const string = llib.string;
const memAmnt:usize = 5000;

const Token = llib.token;
pub const Tokens:type = Arrlist(Token);
const mem = std.mem;
const Allocat = mem.Allocator;

pub fn itr(buff:anytype, cat:Allocat) !?Tokens {
  @setEvalBranchQuota(10000);
  var res = Token{
    .state = .start,
    .tag = .unknown
  };
  var i:usize = if (mem.startsWith(u8, buff, "\xEF\xBB\xBF")) 3 else 0;
  var tokens = Tokens.init(cat);
  defer tokens.deinit();
  var gbuff:string = string.init(cat);
  defer gbuff.deinit();

  try gbuff.alloc(memAmnt) catch |err|{
    if (err == string.errors.AllocateFailure) {
      panic("Failed to allocate {any} memory", .{memAmnt});
    }
  };
  while (i < buff.len) : (i += 1) {
    const ch = buff[i];
    switch (ch) {
      ' ', '\t', '\r' => {
        res.lcol[0] += 1;
        switch(res.state) {
          .identifier => {
            if (res.tag != .identification) continue;
            res.region[1] = i - 1;
            try tokens.append(res);
            gbuff.clearAll();
            res.state = .unknown;
            res.tag = .whitespace;
            res.region[0] = i+1;
            res.region[1] = i+1;
            continue;
          },
          .comment, .string => {
            continue;
          },
          else => {
            res.region[0] = i + 1;
            gbuff.clearAll();
          }
        }
      },
      '\n' => {
        res.lcol[0] = 0;
        res.lcol[1] += 1;
        switch(res.state) {
          .identifier => {
            res.region[1] = i - 1;
            try tokens.append(res);
            gbuff.clearAll();
          },
          .comment, .string => {
            continue;
          },
          else => {}
        }
        res.region[0] = i + 1;
        res.region[1] = i + 1;
        res.state = .newline;
        res.tag = .whitespace;
        try tokens.append(res);
        gbuff.clearAll();
      },
      '$' => {
        res.lcol[0] += 1;
        // gbuff.assumeWrite([1]u8{ch});
        switch(res.state) {
          .comment, .string => continue,
          else => {}
        }
        res.state = .identifier;
        res.tag = .declaration;
      },
      'a'...'z', 'A'...'Z' => {
        res.lcol[0] += 1;
        try gbuff.write([1]u8{ch}, gbuff.len);
        if (res.state == .comment or res.state == .string) {
          continue;
        }
        if (res.state == .identifier) {
          res.tag = .identification;
          res.region[0] = i;
        }
        // res.state = .identifier;
        // res.tag = .
      },
      '0'...'9' => {
        res.lcol[0] += 1;
        if (res.state == .righthand and res.tag == .expression) {
          res.state = .expression;
          res.tag = .unknown;
        }
      },
      '=' => {
        res.lcol[0] += 1;
        if (res.state == .identifier and res.tag == .identification) {
          res.state = .righthand;
          res.tag = .expression;
        }
      },
      else => {
        // if (i % 1 == 0) print("\n", .{});
        res.lcol[0] += 1;
        res.state = .unknown;
        res.tag = .unknown;
        // print("'{c}' = {any}, ", .{ch, ch});
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

// pub fn itr (buff:str, cat:std.mem.Allocator) !?Tokens {
//   while (i < buff.len) : (i += 1) {
//     const ch = buff[i];
//     if (i == buff.len - 1) {
//       res.state = .EOF;
//       try tokens.append(res);
//       break;
//     }
//   }

//   print("{any}", .{try tokens.toOwnedSlice()});

//   return null;
// }

test "general" {
  const pageCat = std.heap.page_allocator;
  // language proposal 0.1?
  _ = try itr(
  \\$mui<mut>:i = 51+2;
  \\@for<!mut>{expr<2>:2;stmt<1>:3} sct1:(expr); sct2:{stmt}; <{all}>
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
  print("\n", .{});
}