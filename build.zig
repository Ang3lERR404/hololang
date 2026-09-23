const std = @import("std");
const zon = @import("build.zig.zon");
const Build = std.Build;
pub fn build(b:*Build) !void {
  const name = @tagName(zon.name);
  const saman = try std.SemanticVersion.parse(zon.version);
  const t = b.standardTargetOptionsQueryOnly(.{});
  const o = b.standardOptimizeOption(.{
    .preferred_optimize_mode = .ReleaseSmall
  });
  const exe = b.addExecutable(.{
    .name = name,
    .version = saman,
    .root_module = b.createModule(.{
      .optimize = o,
      .target = b.resolveTargetQuery(t),
      .root_source_file = b.path("src/main.zig")
    })
  });
  b.installArtifact(exe);
  const run:struct{cmd:*Build.Step.Run, step:*Build.Step} = .{
    .cmd = b.addRunArtifact(exe),
    .step = b.step("run", "run the build.")
  };
  run.step.dependOn(&run.cmd.step);
}