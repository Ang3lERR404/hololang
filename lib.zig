//! Why the hell are we continuing the perpetuation
//! of complicated functions that basically do the same thing.

const std = @import("std");
const builtin = @import("builtin");

const fs = std.fs;
const File = fs.File;
const io = std.io;
const mem = std.mem;
const heap = std.heap;
const fmt = std.fmt;

const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const string:type = ArrayList(u8);

const print = std.debug.print;

pub const types = enum{
  whitespace, literal, identifier, keyword, symbol, unknown
};

/// better than the damn.. `find(bla:blah, bla2:blah, ...)` and `findReverse(bla:blah, blah2:blah, ...)`
/// which is honestly, stupid.
/// and do try to look through the source, honestly..
/// the abundance of recursive calls is abhorrent..
pub const IterationDirection = enum{
  backwards, forwards
};

/// This structure/interface allows for the internalization
/// and automatic handling of common calls by the old version of
/// the tokenizer.
pub const Token = struct {
  const This = @This();
  typeX:types,
  data:?[]u8,
  allocat:Allocator,
  list:ArrayList(u8),

  /// Initiates a token.
  pub fn init(typeX:types, allocat:Allocator, list:ArrayList(u8)) This {
    return This{
      .typeX = typeX,
      .allocat = allocat,
      .list = list,
      .data = null
    };
  }

  /// Safely disposes of the internal list
  /// and the internal string literal for data disposal.
  pub fn deinit(this:This) void {
    this.list.deinit();
    switch (@typeInfo(@TypeOf(this.data))) {
      .Undefined or .Null => return,
      else => {
        this.allocat.free(this.data);
        return;
      }
    }
  }

  /// Since try and test are both keywords in zig
  /// this simply either iterates backwards or forwards
  /// based on the input data, and will spit out a boolean
  /// of either true or false depending on if it found the given char
  /// in the given string literal.
  fn triTest(chs:*[]const u8, ch:u8, itdr:IterationDirection) bool {
    switch (itdr) {
      .forwards => {
        var i = 0;
        while (i < chs.len) : (i += 1) {
          if (chs[i] != ch) continue;
          return true;
        }
        return false;
      },

      .backwards => {
        var i = chs.len - 1;
        while (i > 0) : (i -= 1) {
          if (chs[i] != ch) continue;
          return true;
        }
        return false;
      }
    }
  }

  /// Add Source Data
  /// which will try to append the given character
  /// at the end of the internal list
  pub fn addSrcDt(this:*This, char: u8) !void {
    try this.list.append(char);
  }

  /// This will simply clear the internal list of it's data
  /// and gives said data to the token at which point it will be finalized
  /// by sending it to a given list of tokens.
  pub fn clear(this:*This, tokens:ArrayList(This)) !void {
    this.data = try this.list.toOwnedSlice();
    try tokens.append(this);
  }
};

const TokenList = ArrayList(Token);

pub fn tokenize(data:[]u8, alloc:Allocator) ![]Token {
  var tokens = TokenList.init(alloc);

  var i:usize = 0;
  var states = &[_]bool{
    false, false
  };

  var token = Token.init();

  while (i < data.len) : (i += 1) {
    const ch = data[i];

    switch (ch) {
      ' ', '\n', '\r', ';' => {
        if (Token.triTest(" ;", ch, .forwards) and (states[0] or states[1])) {

        }
      }
    }
  }
}
// pub fn tokenize(data:[]u8, alloc:Allocator) ![]Token {
//   while (i < data.len) : (i += 1) {

//     switch (cs) {
//       ' ', '\n', '\r', ';' => |ch| {
//         if ((ch == ' ' or ch == ';') and (nb == true or ib == true)) {
//           const str = try whole.toOwnedSlice();
//           var res:Token.subTypes = undefined;
//           if (nb) {
//             nb = false;
//             res = .number;
//           } else {
//             ib = false;
//             res = .identifier;
//           }
//           try tokens.append(Token.init(.unknown, res, str));
//           continue;
//         }

//         if ((ch == '\r' and fu == '\n') or ch == '\n') {
//           try tokens.append(Token.init(.whitespace, .newline, null));
//           continue;
//         }
//         continue;
//       },
//       48...57 => {
//         if (pa == ':') {
//           const str = try whole.toOwnedSlice();
//           ib = false;
//           try tokens.append(Token.init(.symbol, .unknown, str));
//         }
//         if (!nb) nb = true;
//         try whole.append(cs);
//         continue;
//       },
//       33...47, 58, 60...64, 91...96, 123...126 => {
//         if (ib == true or nb == true) {
//           const str = try whole.toOwnedSlice();
//           const res:Token.subTypes = if (ib) .identifier else .number;
//           ib = false;
//           nb = false;
//           try tokens.append(Token.init(.literal, res, str));
//         }

//         if (!ib) ib = true;
//         try whole.append(cs);
//         continue;
//       },
//       97...122, 65...90 => {
//         if (pa == ':') {
//           const str = try whole.toOwnedSlice();
//           ib = false;
//           try tokens.append(Token.init(.symbol, .unknown, str));
//         }
//         if (!ib) ib = true;
//         try whole.append(cs);
//         continue;
//       },
//       else => print("{any} = '{c}'\n", .{cs, cs})
//     }
//   }

//   return tokens.toOwnedSlice();
// }

pub fn slurp(path:anytype, alloc:Allocator) ![]u8 {
  const f = try fs.cwd().openFile(path, File.OpenFlags{
    .mode = .read_only
  });
  defer File.close(f);
  const stat = try File.stat(f);
  const m = try File.readToEndAlloc(f, alloc, @as(usize, stat.size));
  return m;
}