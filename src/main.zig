const std = @import("std");

const Allocat = std.mem.Allocator;
const Array = std.array_list.Managed;
const arenaCat = std.heap.ArenaAllocator;
const Io = std.Io;
const File = Io.File;
const Dir = Io.Dir;
const fs = std.fs;
const Reader = Io.Reader;
const Writer = Io.Writer;

const Token = struct{
  pub const Tag = enum{
    eof, symbol, literal, keyword, whitespace, none, unknown
  };
  pub const Type = enum{
    operator, identifier, open, close, mutable, none, unknown,
    expression, statement, section, situational, delimiter, int,
    scope, float, exponent, bits, octal, decimal, hexadec, comparison
  };
  pub const keywords = std.StaticStringMap(Type).initComptime(.{
    .{"mut", .mutable},
    .{"expr", .expression},
    .{"stmt", .statement},
    .{"sct", .section}
  });
  pub const ID = enum{
    lhand, rhand, ambi,
    none, unknown
  };
  const This = @This();
  const empty = This{
    .tag = .none,
    .tYpe = .none,
    .id = .none,
    .range = [_]usize{0,0},
    .combo = false,
    .comboDepth = 0
  };
  tag:Tag,
  tYpe:Type,
  id:ID,
  range:[2]usize,
  combo:bool,
  comboDepth:usize,

  pub fn grab(this:*const This, str:[]u8) []u8 {
    return str[this.range[0]..this.range[1]];
  }
};
const Tokens = Array(Token);
const Lexer = struct{
  pub const State = enum{
    eof, symbol, literal, keyword, whitespace, none, unknown,
    operator, identifier, open, close, mutable, expression,
    statement, section, situational, delimiter, int, scope,
    start, float, exponent, bits, octal, decimal, hexadec,
    possibleCombo, combo
  };
  fn mini(comptime t:type) type {
    return struct{
      const This1 = @This();
      prev:*t,
      cur:*t,
      futur:*t,
      fn init(prev:*t, cur:*t, futur:*t) This1 {
        return .{
          .prev = prev,
          .cur = cur,
          .futur = futur
        };
      }
    };
  }
  const This = @This();
  const mU8 = mini(u8);
  const mToken = mini(Token);
  const empty = This{
    .buf = undefined,
    .tokens = undefined,
    .arena = undefined,
    .prevState = .none,
    .idx = 0
  };
  buf:[]u8,
  tokens:Tokens,
  prevState:State,
  arena:arenaCat,
  idx:usize,

  fn init(path:[]const u8, initz:std.process.Init, cat:Allocat) !This {
    const io = initz.io;
    var this:This = .empty;
    this.arena = .init(cat);
    this.tokens = .init(this.arena.allocator());
    this.buf = try Dir.cwd().readFileAlloc(io, path, this.arena.allocator(), .unlimited);
    return this;
  }

  pub fn deinit(this:*This) void {
    _ = this.arena.reset(.free_all);
  }

  pub fn eat(this:*This, res:*Token, inc:bool) !void {
    if (inc) this.idx += 1;
    res.range[1] = this.idx;
    try this.tokens.append(res.*);
  }

  const SingoManOpt = union(enum){
    single:u8,
    many:[]u8,
    none:void
  };

  fn incOver(ch:u8, toBeIncdOver:[]u8) bool {
    var i:usize = 0;
    while (i < toBeIncdOver.len) : (i += 1) {
      const incdIota = toBeIncdOver[i];
      if (ch != incdIota) continue;
      return true;
    }
    return false;
  }

  pub fn peekComb(this:*This, incr:usize, needles:SingoManOpt, breakers:SingoManOpt) bool {
    const incd = this.buf[this.idx+incr];
    const incd2 = this.buf[this.idx+(incr+1)];
    return switch(needles) {
      .single => |needle| {
        const res1 = incd == needle;
        if (!res1) return false;
        return switch(breakers) {
          .single => |breaker| incd2 == breaker,
          .many => |breakz| incOver(incd2, breakz),
          .none => true
        };
      },
      .many => |needlz| {
        const res1 = incOver(incd, needlz);
        if (!res1) return false;
        return switch(breakers) {
          .single => |breaker| incd2 == breaker,
          .many => |breakz| incOver(incd2, breakz),
          .none => true
        };
      },
      else => switch(breakers) {
        .single => |breaker| incd2 == breaker,
        .many => |breakz| incOver(incd2, breakz),
        .none => false
      }
    };
  }

  pub fn next(this:*This) !void {
    this.tokens.allocator.ptr = &this.arena;
    var res:Token = .empty;
    res.range[0] = 0;
    _ = state: switch(State.start) {
      .start => {
        if (this.idx >= this.buf.len) {
          res.range = [2]usize{this.idx, this.idx};
          res.tag = .eof;
          try this.tokens.append(res);
          break :state;
        }
        switch(this.buf[this.idx]) {
          0 => {
            res.range[0] = this.idx;
            res.range[1] = this.idx;
            res.tag = .eof;
            try this.tokens.append(res);
            continue :state .eof;
          },
          ' ', '\n', '\r', '\t' => {
            res.tag = .whitespace;
            continue :state .whitespace;
          },
          '$','<','>',':','=','+','@','!',';','{',
          '(','[', => {
            res.tag = .symbol;
            if (this.peekComb(0,.{.many = "<[({"},.{.none = void})) res.tYpe = .open;
            continue :state .symbol;
          },
          'a'...'z','A'...'Z','_' => {
            res.tag = .literal;
            res.tYpe = .identifier;
            continue :state .identifier;
          },
          '0'...'9' => {
            res.tag = .literal;
            res.tYpe = .int;
            continue :state .int;
          },
          else => {
            this.idx += 1;
            continue :state .start;
          }
        }
      },
      .whitespace => {
        this.idx += 1;
        switch(this.buf[this.idx]) {
          ' ', '\n', '\r', '\t' => continue :state .whitespace,
          else => {
            try this.eat(&res, false);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        }
      },
      .symbol => {
        switch(this.buf[this.idx]) {
          '$','@' => {
            res.tYpe = .identifier;
            res.id = .lhand;
            try this.eat(&res, true);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          },
          '!','+' => {
            res.tYpe = .operator;
            res.id = .ambi;
            continue :state .possibleCombo;
          },
          '<' => {
            res.id = .none;
            continue :state .possibleCombo;
          },
          else => {
            res = .empty;
            this.idx += 1;
            res.range[0] = this.idx;
            continue :state .start;
          }
        }
      },
      .possibleCombo => switch(this.buf[this.idx]) {
        '!' => switch(this.buf[this.idx+1]) {
          '=' => {
            res.tYpe = .comparison;
            res.id = .rhand;
            continue :state .combo;
          },
          else => {
            res.tYpe = .operator;
            res.id = .ambi;
            try this.eat(&res, true);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        },
        '+' => switch(this.buf[this.idx+1]) {
          '=', '+' => {
            res.tYpe = .operator;
            res.id = .rhand;
            res.combo = true;
            res.comboDepth += 1;
            continue :state .combo;
          },
          else => {
            res.tYpe = .operator;
            res.id = .ambi;
            try this.eat(&res, true);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        },
        '<' => switch(this.buf[this.idx+1]) {
          '=' => {
            res.tYpe = .comparison;
            res.id = .rhand;
            res.combo = true;
            res.comboDepth += 1;
            continue :state .combo;
          },
          ':','!','-' => {
            res.tYpe = .scope;
            res.id = .unknown;
            res.combo = true;
            res.comboDepth += 1;
            continue :state .scope;
          },
          else => {
            res.tYpe = .scope;
            res.id = .unknown;
            try this.eat(&res, true);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        }
      },
      
      .int => {
        this.idx += 1;
        switch(this.buf[this.idx]) {
          // TODO: To be worked on later.
            // 'b','B', => {
            //   if (this.buf[this.idx-1] != '0' and (this.buf[this.idx-2] != ' ' or
            //       this.buf[this.idx-2] != '\t' or this.buf[this.idx-2] != '\n' or
            //       this.buf[this.idx-2] != '\r'))
            //     continue :state .int;
            //   res.tYpe = .bits;
            //   continue :state .bits;
            // },
            // 'o','O' => {
            //   if (this.buf[this.idx-1] != '0' and (this.buf[this.idx-2] != ' ' or
            //       this.buf[this.idx-2] != '\t' or this.buf[this.idx-2] != '\n' or
            //       this.buf[this.idx-2] != '\r'))
            //     continue :state .int;
            //   res.tYpe = .octal;
            //   continue :state .octal;
            // },
            // 'd','D' => {
            //   if (this.buf[this.idx-1] != '0' and (this.buf[this.idx-2] != ' ' or
            //       this.buf[this.idx-2] != '\t' or this.buf[this.idx-2] != '\n' or
            //       this.buf[this.idx-2] != '\r'))
            //     continue :state .int;
            //   res.tYpe = .decimal;
            //   continue :state .decimal;
            // },
            // 'x','X' => {
            //   if (this.buf[this.idx]-1 != '0' and (this.buf[this.idx-2] != ' ' or
            //       this.buf[this.idx-2] != '\t' or this.buf[this.idx-2] != '\n' or
            //       this.buf[this.idx-2] != '\r'))
            //     continue :state .int;
            //   res.tYpe = .hexadec;
            //   continue :state .hexadec;
            // },
          '0'...'9' => continue :state .int,
          '.' => continue :state .float,
          'e','E' => continue :state .exponent,
          else => {
            res.range[1] = this.idx;
            try this.eat(&res, false);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        }
      },
      .float => {
        res.tYpe = .float;
        this.idx += 1;
        switch(this.buf[this.idx]) {
          '0'...'9' => continue :state .float,
          'e','E' => continue :state .exponent,
          else => {
            res.range[1] = this.idx;
            try this.eat(&res, false);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        }
      },
      .exponent => {
        res.tYpe = .exponent;
        this.idx += 1;
        switch(this.buf[this.idx]) {
          '0'...'9','.' => continue :state .exponent,
          else => {
            res.range[1] = this.idx;
            try this.eat(&res, false);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        }
      },
      .identifier => {
        this.idx += 1;
        switch(this.buf[this.idx]) {
          'a'...'z','A'...'Z','0'...'9','_' => continue :state .identifier,
          else => {
            res.range[1] = this.idx;
            const word = res.grab(this.buf);
            if (Token.keywords.get(word)) |tYpe| {
              res.tag = .keyword;
              res.tYpe = tYpe;
            } else {
              res.tYpe = .identifier;
            }
            try this.eat(&res, false);
            res = .empty;
            res.range[0] = this.idx;
            continue :state .start;
          }
        }
      },
      .eof => break :state .eof,
      else => continue :state .start
    };
  }
};

const Parser = struct{
  const This = @This();
  const empty = This{
    .buf = undefined,
    .tokens = undefined
  };
  tokens:[]Token,
  buf:[]u8,
  fn init(buf:[]u8, tokens:[]Token) This {
    return .{
      .buf = buf,
      .tokens = tokens
    };
  }

  pub fn parse(this:This, out:anytype) !void {
    var i:usize = 0;
    while (i < this.tokens.len) : (i+=1) {
      const tk = this.tokens[i];
      if (tk.tag == .whitespace) continue;
      try out.print("'{s}'\n", .{tk.grab(this.buf)});
    }
    try out.flush();
  }
};

pub fn main(init:std.process.Init) !void {
  var lex:Lexer = try .init("./main.holo", init, std.heap.page_allocator);
  defer lex.deinit();

  var buf:[2046]u8 = undefined;
  var impl = File.stdout().writer(init.io, &buf);
  const out = &impl.interface;

  try lex.next();

  try out.print("\n{any}\n", .{lex.tokens.items});
  try out.flush();

  const dummyP:Parser = .init(lex.buf, lex.tokens.items[0..lex.tokens.items.len]);
  try dummyP.parse(out);
}