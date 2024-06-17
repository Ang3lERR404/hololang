const llib = @import("./llib.zig");
const std = llib.std;
const This = @This();

pub const States = enum {
  ///The start of the program.
  start,

  ///An identifier, typically what's used as variable/constant names
  identifier,

  ///We're under a keyword.
  keyword,

  ///We don't know the state.
  unknown,

  ///We encountered an expression.
  expression,

  ///Identification of an identifier, typically just saying that the variable/constant is at x,y,z point
  id_idtf,

  ///Identifier Declaration, typically used to assign vars/consts a value.
  id_dclr,

  ///A Comment
  comment,

  ///A Multiline comment
  multi_comment,

  ///defining if something can be immutable or not.
  mutability,

  ///Assembly literal code.
  assembly,

  ///End Of File
  EOF,

  ///How a user-defined keyword will function
  keyword_function,

  ///How a thing will.. do things
  statement,

  ///Parameters that should/can/are being passed to a given function.
  parameters,

  ///Special denotations like <-:tosource:->
  special,

  ///If thing has things inside of it.
  object,

  ///If we're pointing towards a thing without bringing it over.
  reference,

  ///If we're bringing a thing we're pointing towards over.
  dereference,

  ///String literal
  string,

  ///Number literal
  number,

  ///Object literal
  objectltrl,

  ///Array literal
  arrayltrl,

  ///New Line
  newline
};

state:States,
tag:Tag,
region:[]usize,
lcol:[]usize,

pub const Tag = enum {
  erronious, symbol, literal, eof,
  unknown
};

pub fn init(state:States, tag:Tag, region:[]usize, lcol:[]usize) This {
  return This{
    .state = state,
    .tag = tag,
    .region = region,
    .lcol = lcol
  };
}