const std = @import("std");

pub const This = @This();

tag:Tag,
loc:Loc,
comboLayer:usize,

pub const Loc = struct {
  start:usize,
  end:usize
};

pub var keywords = std.StaticStringMap(Tag).initComptime(.{
  .{"codes", .kwCodes},
  .{"mut", .kwMutable},
  .{"expr", .kwExpression},
  .{"stmt", .kwStatement},
  .{"sct", .kwSection},
  .{"all", .kwAll},
  .{"fn", .kwFunction},
  .{"anytype", .kwAnytype},
  .{"type", .kwType},
  .{"comptime", .kwComptime},
  .{"test", .kwTest}
});

pub fn gKeyword(bytes:[]const u8) ?Tag {
  return keywords.get(bytes);
}

pub const Tag = enum {
  //unknown
    invalid,
    idt,
    strLtrl,
    cLtrl,
    eof,
    builtin,
    combo,
  // symbols
    bang,
    pipe,
    eql,
    lParen,
    rParen,
    semic,
    perc,
    lBrace,
    rBrace,
    lBrckt,
    rBrckt,
    periodt,
    elli2,
    elli3,
    caret,
    plus,
    minus,
    astr,
    arrow,
    colon,
    slash,
    comma,
    amper,
    abl,
    abr,
    tilde,
    numltrl,
    docCmt,
    ctnDocCmt,
    doll,
    hash,
    at,
    question,
  // Keywords
    kwCodes,
    kwMutable,
    kwExpression,
    kwStatement,
    kwSection,
    kwAll,
    kwFunction,
    kwAnytype,
    kwType,
    kwComptime,
    kwTest,
  pub fn lexeme(tag:Tag) ?[]const u8 {
    return switch (tag) {
      .invalid,
      .idt,
      .strLtrl,
      .cLtrl,
      .eof,
      .builtin,
      .numltrl,
      .docCmt,
      .ctnDocCmt,
      .combo => null,

      .bang => "!",
      .pipe => "|",
      .eql => "=",
      .lParen => "(",
      .rParen => ")",
      .semic => ";",
      .perc => "%",
      .lBrace => "[",
      .rBrace => "]",
      .lBrckt => "{",
      .rBrckt => "}",
      .periodt => ".",
      .elli2 => "..",
      .elli3 => "...",
      .caret => "^",
      .plus => "+",
      .minus => "-",
      .astr => "*",
      .arrow => "->",
      .colon => ":",
      .slash => "/",
      .comma => ",",
      .amper => "&",
      .question => "?",
      .abl => "<",
      .abr => ">",
      .tilde => "~",
      .kwAll => "all",
      .kwCodes => "codes",
      .kwExpression => "expr",
      .kwFunction => "fn",
      .at => "@",
      .doll => "$",
      .hash => "#",
      .kwMutable => "mut",
      .kwSection => "sct",
      .kwStatement => "stmt",
      .kwAnytype => "anytype",
      .kwComptime => "comptime",
      .kwTest => "test",
      .kwType => "type"
    };
  }
  pub fn symbol(tag:Tag) []const u8 {
    return tag.lexeme() orelse switch (tag) {
      .invalid => "Invalid Token",
      .idt => "An Identifier",
      .strLtrl => "A String Literal",
      .cLtrl => "A Char Literal",
      .eof => "EOF",
      .builtin => "A Builtin Function",
      .numltrl => "A Number Literal",
      .docCmt, .ctnDocCmt => "A Document Comment",
      else => unreachable
    };
  }
};

pub const Tokenizer = struct {
  const This1 = @This();
  buffer:[:0]const u8,
  idx:usize,
  pub fn dump(this:*This1, token:*const This) This1 {
    std.debug.print("{s} \"{s}\"\n", .{@tagName(token.tag), this.buffer{this.buffer[token.loc.start..token.loc.end]}});
  }
  pub fn init(buffer:[:0]const u8) This1 {
    return .{
      .buffer = buffer,
      .idx = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0
    };
  }

  const State = enum {
    start, expNl, idt, builtin,
    strltrl, cltrl, backslash,
    eql, bang, pipe, minus, aster,
    slash, linecmtS, linecmt, doccmtS, doccmt,
    int, intExp, intPrd, float, fXponent, amper,
    caret, perc, plus, anglBL, anglBR, pdt, pdt2, sawAt,
    invalid, combo
  };

  pub fn next(this:*This1) This {
    var res:This = .{
      .tag = undefined,
      .comboLayer = 0,
      .loc = .{
        .start = this.idx,
        .end = this.idx,
      }
    };

    state: switch (State.start) {
      .start => switch (this.buffer[this.idx]) {
        0 => {
          if (this.idx == this.buffer.len) {
            return .{
              .tag = .eof,
              .loc = .{
                .start = this.idx,
                .end = this.idx
              }
            };
          } else
            continue :state .invalid;
        },
        ' ', '\n', '\t', '\r' => {
          this.idx += 1;
          res.loc.start = this.idx;
          continue :state .start;
        },
        '"' => {
          res.tag = .strLtrl;
          continue :state .strltrl;
        },
        '\'' => {
          res.tag = .cLtrl;
          continue :state .cltrl;
        },
        'a'...'z', 'A'...'Z', '_' => {
          res.tag = .idt;
          continue :state .idt;
        },
        '@' => continue :state .sawAt,
        '=' => continue :state .eql,
        '!' => continue :state .bang,
        '|' => continue :state .pipe,
        '(' => {
          res.tag = .lParen;
          this.idx += 1;
        },
        ')' => {
          res.tag = .rParen;
          this.idx += 1;
        },
        '[' => {
          res.tag = .lBrace;
          this.idx += 1;
        },
        ']' => {
          res.tag = .rBrace;
          this.idx += 1;
        },
        ';' => {
          res.tag = .semic;
          this.idx += 1;
        },
        ',' => {
          res.tag = .comma;
          this.idx += 1;
        },
        '?' => {
          res.tag = .question;
          this.idx += 1;
        },
        ':' => {
          res.tag = .colon;
          this.idx += 1;
        },
        '%' => continue :state .perc,
        '*' => continue :state .aster,
        '+' => continue :state .plus,
        '<' => continue :state .anglBL,
        '>' => continue :state .anglBR,
        '^' => continue :state .caret,
        '{' => {
          res.tag = .lBrace;
          this.idx += 1;
        },
        '}' => {
          res.tag = .rBrace;
          this.idx += 1;
        },
        '~' => {
          res.tag = .tilde;
          this.idx += 1;
        },
        '.' => continue :state .pdt,
        '-' => continue :state .minus,
        '/' => continue :state .slash,
        '&' => continue :state .amper,
        '0'...'9' => {
          res.tag = .numltrl;
          this.idx += 1;
          continue :state .int;
        },
        else => continue :state .invalid
      },

      .expNl => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          0 => {
            if (this.idx == this.buffer.len)
              res.tag = .invalid
            else
              continue :state .invalid;
          },
          '\n' => {
            this.idx += 1;
            res.loc.start = this.idx;
            continue :state .start;
          },
          else => continue :state .invalid
        }
      },

      .invalid => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          0 => {if (this.idx == this.buffer.len) res.tag = .invalid else continue :state .invalid;},
          '\n' => res.tag = .invalid,
          else => continue :state .invalid
        }
      },

      .sawAt => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          0, '\n' => res.tag = .invalid,
          '"' => {
            res.tag = .idt;
            continue :state .strltrl;
          },
          'a'...'z', 'A'...'Z', '_' => {
            res.tag = .builtin;
            continue :state .builtin;
          },
          else => continue :state .invalid
        }
      },

      .amper => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          '=' => continue :state .combo,
          else => res.tag = .amper
        }
      },

      .aster => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          '=', '*', '%', '|' => continue :state .combo,
          else => res.tag = .aster
        }
      },

      .perc => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          '=' => continue :state .combo,
          else => res.tag = .perc
        }
      },

      .plus => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          '=', '+', '%', '|' => continue :state .combo,
          else => res.tag = .plus
        }
      },

      .caret => {
        this.idx += 1;
        switch (this.buffer[this.idx]) {
          '=' => continue :state .combo,
          else => res.tag = .caret
        }
      },

      .idt => {
        
      }
    }
  }
};