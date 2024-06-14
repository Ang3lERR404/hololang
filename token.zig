//! A token represents really anything.
//! like in languages in real life

const llib = @import("llib.zig");
const std = llib.std;

const This = @This();

tag:GTag,
loc:Loc,

/// General tags
/// it can either be erronious, identifiers, or symbols
pub const GTag = enum {
  erronious, identifier, symbol, EOF,
  unknown,

  /// Specific tags.
  pub var sTag = enum {};
};

/// Location
pub const Loc = struct {
  /// Start
  s:usize,
  /// End
  e:usize
};