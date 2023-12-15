const std = @import("std");

pub fn addDay(b: *std.Build, comptime name: []const u8, common: *std.build.Module, steps: []const *std.build.Step.Compile) void {
    const day = b.addModule(name, .{
        .source_file = .{ .path = "src/" ++ name ++ ".zig" },
        .dependencies = &.{
            .{ .name = "common", .module = common },
        },
    });
    for (steps) |step| {
        step.addModule(name, day);
    }
}

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aoc2023",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests.zig" },

        .target = target,
        .optimize = optimize,
    });

    const common = b.addModule("day01", .{
        .source_file = .{ .path = "src/common.zig" },
    });
    exe.addModule("common", common);
    unit_tests.addModule("common", common);

    const steps = [_]*std.build.Step.Compile{ exe, unit_tests };
    addDay(b, "day01", common, &steps);
    addDay(b, "day02", common, &steps);
    addDay(b, "day03", common, &steps);
    addDay(b, "day04", common, &steps);
    addDay(b, "day05", common, &steps);
    addDay(b, "day06", common, &steps);
    addDay(b, "day07", common, &steps);
    addDay(b, "day08", common, &steps);
    addDay(b, "day09", common, &steps);
    addDay(b, "day10", common, &steps);
    addDay(b, "day11", common, &steps);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
