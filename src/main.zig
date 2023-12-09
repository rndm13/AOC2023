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

pub fn main() !void {
    const out_w = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input_buffer: []u8 = try alloc.alloc(u8, 2 << 16);
    defer alloc.free(input_buffer);

    {
        const day01_file = try std.fs.cwd().openFile("inputs/day01.txt", .{});
        defer day01_file.close();

        _ = try day01_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day01_out = try day01.solveFirst(input, alloc);
            defer alloc.free(day01_out);

            try out_w.print("Day 01 first star finished with:\n{s}\n", .{day01_out});
        }

        {
            const day01_out = try day01.solveSecond(input, alloc);
            defer alloc.free(day01_out);

            try out_w.print("Day 01 second star finished with:\n{s}\n", .{day01_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day02_file = try std.fs.cwd().openFile("inputs/day02.txt", .{});
        defer day02_file.close();

        _ = try day02_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day02_out = try day02.solveFirst(input, alloc);
            defer alloc.free(day02_out);

            try out_w.print("Day 02 first star finished with:\n{s}\n", .{day02_out});
        }

        {
            const day02_out = try day02.solveSecond(input, alloc);
            defer alloc.free(day02_out);

            try out_w.print("Day 02 second star finished with:\n{s}\n", .{day02_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day03_file = try std.fs.cwd().openFile("inputs/day03.txt", .{});
        defer day03_file.close();

        _ = try day03_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day03_out = try day03.solveFirst(input, alloc);
            defer alloc.free(day03_out);

            try out_w.print("Day 03 first star finished with:\n{s}\n", .{day03_out});
        }

        {
            const day03_out = try day03.solveSecond(input, alloc);
            defer alloc.free(day03_out);

            try out_w.print("Day 03 second star finished with:\n{s}\n", .{day03_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day04_file = try std.fs.cwd().openFile("inputs/day04.txt", .{});
        defer day04_file.close();

        _ = try day04_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day04_out = try day04.solveFirst(input, alloc);
            defer alloc.free(day04_out);

            try out_w.print("Day 04 first star finished with:\n{s}\n", .{day04_out});
        }

        {
            const day04_out = try day04.solveSecond(input, alloc);
            defer alloc.free(day04_out);

            try out_w.print("Day 04 second star finished with:\n{s}\n", .{day04_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day05_file = try std.fs.cwd().openFile("inputs/day05.txt", .{});
        defer day05_file.close();

        _ = try day05_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day05_out = try day05.solveFirst(input, alloc);
            defer alloc.free(day05_out);

            try out_w.print("Day 05 first star finished with:\n{s}\n", .{day05_out});
        }

        {
            const day05_out = try day05.solveSecond(input, alloc);
            defer alloc.free(day05_out);

            try out_w.print("Day 05 second star finished with:\n{s}\n", .{day05_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day06_file = try std.fs.cwd().openFile("inputs/day06.txt", .{});
        defer day06_file.close();

        _ = try day06_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day06_out = try day06.solveFirst(input, alloc);
            defer alloc.free(day06_out);

            try out_w.print("Day 06 first star finished with:\n{s}\n", .{day06_out});
        }

        {
            const day06_out = try day06.solveSecond(input, alloc);
            defer alloc.free(day06_out);

            try out_w.print("Day 06 second star finished with:\n{s}\n", .{day06_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day07_file = try std.fs.cwd().openFile("inputs/day07.txt", .{});
        defer day07_file.close();

        _ = try day07_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day07_out = try day07.solve(input, alloc, false);
            defer alloc.free(day07_out);

            try out_w.print("Day 07 first star finished with:\n{s}\n", .{day07_out});
        }

        {
            const day07_out = try day07.solve(input, alloc, true);
            defer alloc.free(day07_out);

            try out_w.print("Day 07 second star finished with:\n{s}\n", .{day07_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day08_file = try std.fs.cwd().openFile("inputs/day08.txt", .{});
        defer day08_file.close();

        _ = try day08_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day08_out = try day08.solveFirst(input, alloc);
            defer alloc.free(day08_out);

            try out_w.print("Day 08 first star finished with:\n{s}\n", .{day08_out});
        }

        {
            const day08_out = try day08.solveSecond(input, alloc);
            defer alloc.free(day08_out);

            try out_w.print("Day 08 second star finished with:\n{s}\n", .{day08_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }

    {
        const day09_file = try std.fs.cwd().openFile("inputs/day09.txt", .{});
        defer day09_file.close();

        _ = try day09_file.readAll(input_buffer);
        const input = std.mem.trimRight(u8, input_buffer, &[_]u8{ 0, '\n', '\r', '\t', ' ' });

        {
            const day09_out = try day09.solve(input, alloc, .First);
            defer alloc.free(day09_out);

            try out_w.print("Day 09 first star finished with:\n{s}\n", .{day09_out});
        }

        {
            const day09_out = try day09.solve(input, alloc, .Second);
            defer alloc.free(day09_out);

            try out_w.print("Day 09 second star finished with:\n{s}\n", .{day09_out});
        }

        @memset(input_buffer, 0); // clear the buffer for next day
    }
}
