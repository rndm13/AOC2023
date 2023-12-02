const std = @import("std");

comptime {
    _ = @import("day01.zig");
    _ = @import("day02.zig");
}

test {
    std.testing.refAllDecls(@This());
}
