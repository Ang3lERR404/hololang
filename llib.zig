pub const std = @import("std");
pub const token = @import("token.zig");
pub const tokenizer = @import("tokenizer.zig");

pub const print = std.debug.print;
pub const assert = std.debug.assert;
pub const expect = std.testing.expect;

pub const sW = std.mem.startsWith;
pub const states = enum {
  start, identifier, symbol, unknown
};