const std = @import("std"); const builtin = @import("builtin");

const This = @This();

pub const errors = error{
  ResizeFailure, AppendFailure, AllocateFailure, Empty,
  OutOfMemory, InvalidIndex, InvalidRange, FormattingFailure
};

const mem = std.mem; const heap = std.heap; const debug = std.debug; const testing = std.testing;
const Allocat = mem.Allocator; const unicode = std.unicode;

const print = debug.print; const assert = debug.assert; const expect = testing.expect;

buff:?[]u8, len:usize, cat:Allocat, origBuff:?[]u8,

pub fn init(cat:Allocat) This {
  return This{
    .buff = undefined,
    .len = 0,
    .cat = cat,
    .origBuff = undefined
  };
}

pub fn initWD(cat:Allocat, str:anytype) This {
  var stor = init(cat);
  stor.alloc(str.len);
  stor.write(str);
  return stor;
}

pub fn free(this:This, memor:anytype) void {
  this.cat.free(memor);
}

pub fn deinit(this:This) void {
  if (this.len == 0) return;
  this.cat.free(this.buff.?);
}

pub fn clear (this:*This, s:usize, e:usize) void {
  var i = s;
  while (i < e) : (i += 1)
    this.buff.?[i] = 0;
}

pub fn alloc(this:*This, comptime size:usize) errors!void {
  const oL = this.len;
  if (this.len > 0) {
    if (size < this.len) this.len = size;
    this.buff.? = this.cat.realloc(this.buff.?, size) catch return errors.AllocateFailure;
    this.clear(oL, this.buff.?.len);
    this.len = this.buff.?.len;
    return;
  }
  this.buff.? = this.cat.alloc(u8, size) catch return errors.AllocateFailure;
  this.len = this.buff.?.len;
  this.clear(0, this.len);
}

pub fn addAlloc(this:*This, comptime size:usize) errors!void {
  const oL = this.len;
  this.buff.? = this.cat.realloc(this.buff.?, oL + size) catch return errors.AllocateFailure;
  this.clear(oL, this.buff.?.len);
  this.len = this.buff.?.len;
}

pub fn write(this:*This, str:anytype) void {
  var i:usize = 0;
  while (i < str.len) : (i += 1)
    this.buff.?[i] = str[i];
}

pub fn writeFrom(this:*This, str:anytype, s:usize) void {
  var i:usize = 0;
  while (i < this.len) : (i += 1) {
    if (this.buff.?[i] != 0) continue;
    if (i != s) continue;
    var j:usize = 0;
    while (j < str.len) : (j += 1)
      this.buff.?[i + j] = str[j];
    break;
  }
}

pub fn truncate (this:*This) !void {
  try this.alloc(this.len);
}

pub fn eql(this:*This, str:anytype, comptime rI:bool) if (rI) ?usize else bool {
  return if (rI == true) 
    mem.indexOfDiff(u8, this.buff.?, str)
  else
    mem.eql(u8, this.buff.?, str);
}

pub fn toStr(this:*This) []const u8 {
  if (this.buff) |buff| return buff[0..this.len];
  return "";
}

pub fn pop(this:*This) ?u8 {
  if (this.len == 0) return null;
  if (this.buff) |buff| {
    var i:usize = 0;
    while(i < this.len) {
      const size = This.getUTF8Size(buff[i]);
      if (i + size >= this.len) break;
      i += size;
    }
    const ret = buff[i..this.len];
    this.len -= (this.len - i);
    return ret;
  }
  return null;
}

pub fn getIndex(unic:[]const u8, i:usize, real:bool) ?usize {
  var j:usize = 0; var k:usize = 0;
  while (j < unic.len) {
    if (real)
      if (k == i) return j;
    if (j == i) return k;

    j += This.getSize(unic[j]);
    k += 1;
  }
  return null;
}

inline fn getSize(char:u8) u3 {
  return unicode.utf8ByteSequenceLength(char) catch {
    return 1;
  };
}

pub fn charAt(this:*This, i:usize) ?[]const u8 {
  if (this.buff) |buff| {
    if (This.getIndex(buff, i, true)) |j| {
      return buff[j..(j + This.getSize(buff[j]))];
    }
  }
  return null;
}

pub fn own(this:*This) !?[]u8 {
  if (this.buff != null) {
    const str = this.toStr();
    if (this.cat.alloc(u8, str.len)) |nStr| {
      mem.copyForwards(u8, nStr, str);
      return nStr;
    } else |_| return errors.OutOfMemory;
  }
  return null;
}

pub fn rem(this:*This, ind:usize) !void {
  try this.remRange(ind, ind+1);
}

pub fn remRange(this:*This, s:usize, e:usize) errors!void {
  const len = this.len;
  if (e < s or e > len) return errors.InvalidRange;

  if (this.buff) |buff| {
    const rS = This.getIndex(buff, s, true).?;
    const rE = This.getIndex(buff, e, true).?;
    const dif = rE - rS;

    var i:usize = rE;
    while (i < len) : (i += 1) buff[i - dif] = buff[i];
    this.len -= dif;
  }
}

pub fn find(this:*This, litrl:[]const u8, revr:bool) ?usize {
  if (this.buff) |buff| {
    const ind = if (!revr)
      mem.indexOf(u8, buff[0..this.len], litrl)
    else
      mem.lastIndexOf(u8, buff[0..this.len], litrl);

    if (ind) |i|
      return This.getIndex(buff, i, false);
  }
  return undefined;
}

pub fn rev(this:*This) void {
  if (this.buff) |buff| {
    var i:usize = 0;
    while (i < this.len) {
      const len = This.getSize(buff);
      if (len > 1) mem.reverse(u8, buff[i..(i+len)]);
      i += len;
    }

    mem.reverse(u8, buff[0..this.len]); 
  }
}

pub fn trim(this:*This, whitelist:[]const u8) void {
  if (this.buff) |buff| {
    var i:usize = 0;
    while (i < this.len) : (i += 1) {
      const len = This.getSize(buff[i]);
      if (len > 1 or !This.inWhitelist(buff[i], whitelist)) break;
    }

    if (This.getIndex(buff, i, false)) |k|
      this.remRange(0, k) catch {};
  }
  
}

fn inWhitelist(char:u8, whitelist:[]const u8) bool {
  var i:usize = 0;
  while (i < whitelist.len) : (i += 1) 
    if (whitelist[i] == char) return true;
  return false;
}

pub fn isUTF8(b:u8) bool {
  return ((b & 0x80) > 0) and (((b << 1) & 0x80) == 0);
}

pub fn assumeWrite(this:*This, str:anytype) !void {
  try this.alloc(str.len);
  this.write(str);
}

pub fn assumeWriteFrom(this:*This, str:anytype, s:usize) !void {
  try this.addAlloc(str.len);
  this.writeFrom(str, s);
}

const fmt = std.fmt;

pub fn f(this:*This, comptime fmStr:[]const u8, args:anytype) errors!void {
  this.origBuff = this.own();
  this.buff.? = try fmt.allocPrint(this.cat, fmStr, args) catch return errors.FormattingFailure;
}

pub fn subStr(this:*This, from:usize, to:usize) *This {
  if (this.buff) |b| {
    return initWD(this.*.cat, b[from..to]);
  }
}

pub fn append(this:*This, str:anytype) void {
  var i:usize = 0;
  if (this.buff) |b| {
    while (i < this.len) : (i += 1) {
      const ch = b[i];
      if (ch != 0) continue;
      break;
    }

    this.writeFrom(str, i);
  }
}

pub fn appendChar(this:*This,ch:anytype) void {
  var i:usize = 0;
  if (this.buff) |b| {
    while (i < this.len) : (i+=1) {
      const ch0 = b[i];
      if (ch0 != 0) continue;
      break;
    }

    this.writeFrom([1]u8{ch}, i);
  }
}