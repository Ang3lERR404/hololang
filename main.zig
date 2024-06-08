const std = @import("std");
const builtin = @import("builtin");
const lib = @import("./lib.zig");

const print = &std.debug.print;
const assert = &std.debug.assert;
const expect = &std.testing.expect;

const mem = std.mem;
const heap = std.heap;

const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
  var mep:[]u8 = undefined;

  mep = try lib.slurp("./main.holo", heap.page_allocator);

  const tokens = try lib.tokenize(mep, heap.page_allocator);

  for (tokens, 0..tokens.len) |tkn, i| {
    _ = i;
    print("Type:{any}\nSub-Type:{any}\nContent: '{?s}'\n\n", .{
      tkn.type,
      tkn.subType,
      tkn.content
    });
    // print("{any}\n", .{tkn});
  }

  // print("{any}\n", .{tokens});
}