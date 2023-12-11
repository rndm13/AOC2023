const std = @import("std");
const day01 = @import("day01");
const day02 = @import("day02");
const day03 = @import("day03");
const day04 = @import("day04");
const day05 = @import("day05");
const day06 = @import("day06");
const day07 = @import("day07");
const day08 = @import("day08");
const day09 = @import("day09");
const day10 = @import("day10");

fn doDay(alloc: std.mem.Allocator, input_buffer: []u8, comptime name: []const u8, comptime module: type) !void {
    const out_w = std.io.getStdOut().writer();

    const file = try std.fs.cwd().openFile("inputs/" ++ name ++ ".txt", .{});
    defer file.close();

    _ = try file.readAll(input_buffer);
    const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

    {
        const start = std.time.microTimestamp();
        const out = try module.solveFirst(input, alloc);
        defer alloc.free(out);
        const end = std.time.microTimestamp();

        try out_w.print(name ++ " first star finished in {}μs with:\n{s}\n", .{ end - start, out });
    }

    {
        const start = std.time.microTimestamp();
        const out = try module.solveSecond(input, alloc);
        defer alloc.free(out);
        const end = std.time.microTimestamp();

        try out_w.print(name ++ " second star finished in {}μs with:\n{s}\n", .{ end - start, out });
    }

    @memset(input_buffer, 0); // clear the buffer for next day
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input_buffer: []u8 = try alloc.alloc(u8, 2 << 16);
    defer alloc.free(input_buffer);

    try doDay(alloc, input_buffer, "day01", day01);
    try doDay(alloc, input_buffer, "day02", day02);
    try doDay(alloc, input_buffer, "day03", day03);
    try doDay(alloc, input_buffer, "day04", day04);
    try doDay(alloc, input_buffer, "day05", day05);
    try doDay(alloc, input_buffer, "day06", day06);
    try doDay(alloc, input_buffer, "day07", day07);
    try doDay(alloc, input_buffer, "day08", day08);
    try doDay(alloc, input_buffer, "day09", day09);
    try doDay(alloc, input_buffer, "day10", day10);
}
