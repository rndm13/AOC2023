const std = @import("std");
pub const day01 = @import("day01");

pub fn main() !void {
    const out_w = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const day01_file = try std.fs.cwd().openFile("inputs/day01.txt", .{});
    defer day01_file.close();

    const input_buffer = try alloc.alloc(u8, 2 << 16);
    defer alloc.free(input_buffer);

    _ = try day01_file.readAll(input_buffer);

    {
        const day01_out = try day01.solve_first(input_buffer, alloc);
        defer alloc.free(day01_out);

        try out_w.print("Day 01 first star finished with:\n{s}\n", .{day01_out});
    }

    {
        const day01_out = try day01.solve_second(input_buffer, alloc);
        defer alloc.free(day01_out);

        try out_w.print("Day 01 second star finished with:\n{s}\n", .{day01_out});
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
