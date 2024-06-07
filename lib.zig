const std = @import("std");
const builtin = @import("builtin");
const Token = @import("./token.zig").Tiki;

const fs = std.fs;
const File = fs.File;
const io = std.io;
const mem = std.mem;
const heap = std.heap;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const fmt = std.fmt;

const str:type = []u8;
const print = std.debug.print;

pub fn tokenize(data:[]u8, alloc:Allocator) ![]Token {
  var tokens = ArrayList(Token).init(alloc);

  var i:usize = 0;
  while (i < data.len) : (i += 1) {
    const cs = data[i];

    switch (cs) {
      32, 10, 177, '\r' => |ch| {
        if ((ch == '\r' and data[i+1] == '\n') or ch == '\n') {
          try tokens.append(Token.init(.whitespace, .newline, null));
        }
        continue;
      },
      48...57 => {
        const tkn = tokens.getLast();
        if (tkn.type == .literal and tkn.subType == .number) {

        }
        try tokens.append(Token.init(.literal, .number, cs));
        continue;
      },
      33...47, 58...64, 91...96, 123...126  => {
        try tokens.append(Token.init(.symbol, .unknown, cs));
        continue;
      },
      97...122, 65...90 => {
        try tokens.append(Token.init(.literal, .char, cs));
        continue;
      },
      else => print("{any} = '{c}'\n", .{cs, cs})
    }
  }

  return tokens.toOwnedSlice();
}

pub fn slurp(path:anytype, alloc:Allocator) !str {
  const f = try fs.cwd().openFile(path, File.OpenFlags{
    .mode = .read_only
  });
  defer File.close(f);

  const m = try File.readToEndAlloc(f, alloc, 2048);
  return m;
}