pub const std = @import("std");
pub const token = @import("token.zig");
pub const tokenizer = @import("tokenizer.zig");
pub const tokares = @import("tokares.zig");

pub const print = std.debug.print;
pub const assert = std.debug.assert;
pub const expect = std.testing.expect;

pub const sW = std.mem.startsWith;
pub const states = enum {
  start, identifier, symbol, unknown,
  at, plus, minus, caret, ampersand,
  dollarSign, asterisk, iDIDTF,
  iDCLR, tilde, squig,
  bSlash, fSlash, lParen, rParen,
  lBracket, rBracket, mutabilitiy,
  bang, not, comment, multiCmmnt,
  docCmmnt, eql, semicolon, colon,
  lArrow, rArrow, lCurlBrace, rCurlBrace,
  period, percent, pipe, hash, question,
  underscore, sQuote, dQuote
};