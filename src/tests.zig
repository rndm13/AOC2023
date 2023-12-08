const std = @import("std");

comptime {
    _ = @import("day01.zig");
    _ = @import("day02.zig");
    _ = @import("day03.zig");
    _ = @import("day04.zig");
    _ = @import("day05.zig");
    _ = @import("day06.zig");
    _ = @import("day07.zig");
    _ = @import("day08.zig");
}

test {
    std.testing.refAllDecls(@This());
}
