const llib = @import("llib.zig");
const This = @This();

state:llib.states,
result:llib.token = .{
  .tag = .EOF,
  .loc = .{
    .s = undefined,
    .e = undefined
  }
},
line:usize,
column:usize,

pub fn init(state:llib.states, result:llib.token, line:usize, column:usize) This {
  return This{
    .state = state,
    .result = result,
    .line = line,
    .column = column
  };
}