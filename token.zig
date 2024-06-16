//! A token represents really anything.
//! like in languages in real life

const llib = @import("llib.zig");
const std = llib.std;

const This = @This();

tag:Tag,
loc:Loc,

/// General tags
/// it can either be erronious, identifiers, or symbols
pub const Tag = enum {
  erronious, identifier, symbol, EOF,
  unknown, dollarSign, bang, semicolon, eql,
  lParen, rParen, lBracket, rBracket, period, asterisk,
  colon, ampersand, tilde, lAngleBracket, rAngleBracket,
  minus, plus, caret, rFCurlBrace, lFCurlBrace, comma, squig,
  at, bSlash, fSlash, kwTrue, kwFalse, kwMut, kwExpr, kwStmt,
  kwSct
};

/// Location
pub const Loc = struct {
  /// Start
  s:usize,
  /// End
  e:usize
};