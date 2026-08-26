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
    .tokenType = .Unknown,
    .literal = undefined,
    .lineColl = undefined,
    .literalChar = undefined
  };
  res.lineColl = .{0, 0};
  var i:usize = if (mem.startsWith(u8, buff, "\xEF\xBB\xBF")) 3 else 0;
  var tokens = Tokens.empty;

  var gbuff = string.init(cat);
  defer gbuff.deinit();

  while (i < buff.len) : (i += 1) {
    const ch = buff[i];
    switch (ch) {
      ' ', '\t', '\r' => {
        res.lineColl[0]+=1;
        switch (res.tokenType) {
          .string => {
            res.tokenType = .whitespace;
            res.literalChar = ch;
            try tokens.append(cat, res);
            continue;
          },
          // .ident => {

          // },
          else => {
            continue;
          }
        }
        // if (res.tokenType != .string) continue;
        res.lineColl[0]+=1;
        res.tokenType = .whitespace;
        res.literalChar = ch;
        try tokens.append(cat, res);
        continue;
      },
      '\n' => {
        if (res.tokenType != .string) continue;
        res.lineColl[0]=0;
        res.tokenType = .whitespace;
        res.literalChar = ch;
        try tokens.append(cat, res);
        continue;
      },
      '$' => {
        res.lineColl[0]+=1;
        switch(res.tokenType) {
          .comment, .string => continue,
          else => {}
        }
        res.tokenType = .ident;
        try tokens.append(cat, res);
      },
      'a'...'z','A'...'Z' => {
        res.lineColl[0] += 1;
        gbuff.appendChar(ch);
        switch (res.tokenType) {
          .comment, .string => continue,
          .ident => {
            
          }
        }
      },
      else => {
        print("'{c}' = {any},\n", .{ch, ch});
      }
    }
    //
      // switch (ch) {
        //   'a'...'z', 'A'...'Z' => {
        //     res.lcol[0] += 1;
        //     gbuff.append([1]u8{ch});
        //     if (res.state == .comment or res.state == .string) {
        //       continue;
        //     }
        //     if (res.state == .identifier and res.tag == .declaration) {
        //       res.tag = .identification;
        //       res.region[0] = i;
        //     }
        //     if (res.state == .special and res.tag == .opening) {
        //       res.tag = .mutatable;
        //       res.region[0] = i;
        //       if (gbuff.subStr(0, 3).eql("mut", false)) {
        //         res.region[1] = i;
        //         try tokens.append(res);
        //       }
        //     }
        //     // res.state = .identifier;
        //     // res.tag = .
        //   },
        //   '0'...'9' => {
        //     res.lcol[0] += 1;
        //     if (res.state == .righthand and res.tag == .expression) {
        //       res.state = .expression;
        //       res.tag = .unknown;
        //     }
        //     if (res.state == .identifier and res.tag == .identification) {
        //       gbuff.append([1]u8{ch});
        //     }
        //   },
        //   '=' => {
        //     res.lcol[0] += 1;
        //     if (res.state == .identifier and res.tag == .identification) {
        //       res.state = .righthand;
        //       res.tag = .expression;
        //     }
        //   },
        //   '<' => {
        //     res.lcol[0] += 1;
        //     if (res.state == .identifier and res.tag == .identification) {
        //       res.region[1] = i-1;
        //       try tokens.append(res);
        //       gbuff.clear(0, gbuff.len);
        //     }
        //     res.state = .special;
        //     res.tag = .opening;
        //     try tokens.append(res);
        //   },
        //   '>' => {
        //     res.lcol[0] += 1;
        //     if (res.state == .special) {
        //       res.region[1] = i-1;
        //       try tokens.append(res);
        //       gbuff.clear(0, gbuff.len);
        //     }
        //   },
        //   else => {
        //     // if (i % 1 == 0) print("\n", .{});
        //     res.lcol[0] += 1;
        //     res.state = .unknown;
        //     res.tag = .unknown;
        //     print("'{c}' = {any}, ", .{ch, ch});
        //   }
        // }
    // if (i == buff.len - 1) {
    //   res.state = .EOF;
    //   try tokens.append(res);
    //   break;
    // }
  }
  // print("\n{any}\n", .{try tokens.toOwnedSlice()});
  return null;
}

test "general" {
  const pageCat = std.heap.page_allocator;
  // language proposal 0.1?
  _ = try itr(\\$mui<mut>:i = 51+2;
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