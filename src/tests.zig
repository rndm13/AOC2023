const std = @import("std");

comptime {
    _ = @import("day01.zig");
}

test {
    std.testing.refAllDecls(@This());
}
