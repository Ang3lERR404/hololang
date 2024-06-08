const std = @import("std");
const builtin = @import("builtin");

const fs = std.fs;
const File = fs.File;
const io = std.io;
const mem = std.mem;
const heap = std.heap;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const fmt = std.fmt;

const string:type = ArrayList(u8);
const print = std.debug.print;

pub const Token = struct {
  pub const types = enum {whitespace, literal, symbol, unknown};
  pub const subTypes = enum {identifier, number, lengthy, newline, unknown};
  const thi = @This();
  type:types,
  subType:subTypes,
  content:?[]u8,

  fn init(typ:types, subType:subTypes, content:?[]u8) thi {
    return thi{
      .type = typ,
      .subType = subType,
      .content = content orelse null
    };
  }
};

pub fn tokenize(data:[]u8, alloc:Allocator) ![]Token {
  var tokens = ArrayList(Token).init(alloc);

  var i:usize = 0;
  var whole = string.init(alloc);
  var nb = false;
  var ib = false;
  while (i < data.len) : (i += 1) {
    const cs = data[i];

    switch (cs) {
      ' ', '\n', '\r', ';' => |ch| {
        if ((ch == ' ' or ch == ';') and (nb == true or ib == true)) {
          const str = try whole.toOwnedSlice();
          if (nb) nb = false else ib = false;
          try tokens.append(Token.init(.literal, .number, str));
          continue;
        }

        if ((ch == '\r' and data[i+1] == '\n') or ch == '\n') {
          try tokens.append(Token.init(.whitespace, .newline, null));
          continue;
        }
        continue;
      },
      48...57 => {
        if (!nb) nb = true;
        try whole.append(cs);
        continue;
      },
      33...47, 58, 60...64, 91...96, 123...126  => {
        if (!ib) ib = true;
        try whole.append(cs);
        continue;
      },
      97...122, 65...90 => {
        if (!ib) ib = true;
        try whole.append(cs);
        continue;
      },
      else => print("{any} = '{c}'\n", .{cs, cs})
    }
  }

  return tokens.toOwnedSlice();
}

pub fn slurp(path:anytype, alloc:Allocator) ![]u8 {
  const f = try fs.cwd().openFile(path, File.OpenFlags{
    .mode = .read_only
  });
  defer File.close(f);

  const m = try File.readToEndAlloc(f, alloc, 2048);
  return m;
}