const common = @import("common");
const std = @import("std");

fn parseNumbers(input: []const u8, alloc: std.mem.Allocator) ![]i64 {
    var numbers = std.mem.splitAny(u8, input, " ");

    var result = std.ArrayList(i64).init(alloc);
    defer result.deinit();

    while (numbers.next()) |num| {
        (try result.addOne()).* = try std.fmt.parseInt(i64, num, 10);
    }
    return result.toOwnedSlice();
}

fn extrapolate(input: []i64, alloc: std.mem.Allocator, comptime dir: enum { Next, Prev }) !i64 {
    var numbers = try common.Array2D(i64).init(alloc, input.len, input.len);
    defer numbers.deinit();
    @memcpy(numbers.rowSlice(0), input);

    var sum: i64 = 0;
    var last_row: usize = 0;
    for (0..numbers.rows) |row| {
        const row_slice = numbers.rowSlice(row)[0 .. numbers.rows - row];
        var zeroes = true;
        for (row_slice) |num| {
            zeroes = zeroes and num == 0;
        }

        if (zeroes) {
            break;
        }

        var pairs = std.mem.window(i64, row_slice, 2, 1);
        while (pairs.next()) |pair| {
            const col = (pairs.index orelse row_slice.len - 1) - 1;
            numbers.at(col, row + 1).* = pair[1] - pair[0];
        }

        if (dir == .Next) {
            sum += row_slice[row_slice.len - 1];
        }

        last_row += 1;
    }

    if (dir == .Prev) {
        for (0..last_row) |i| {
            sum = numbers.at(0, last_row - 1 - i).* - sum;
        }
    }

    return sum;
}

pub fn solve(input: []const u8, alloc: std.mem.Allocator, comptime part: enum { First, Second }) ![]const u8 {
    var lines = std.mem.splitAny(u8, input, "\n");
    var sum: i64 = 0;
    while (lines.next()) |line| {
        const parsed = try parseNumbers(line, alloc);
        defer alloc.free(parsed);

        sum += try extrapolate(parsed, alloc, if (part == .First) .Next else .Prev);
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

const expect = std.testing.expect;
test "day 09 first star" {
    const alloc = std.testing.allocator;
    const input =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;
    const output = try solve(input, alloc, .First);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "114"));
}

test "day 09 second star" {
    const alloc = std.testing.allocator;
    const input =
        \\10 13 16 21 30 45
    ;
    const output = try solve(input, alloc, .Second);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "5"));
}

pub fn solveFirst(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    return solve(input, alloc, .First);
}

pub fn solveSecond(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    return solve(input, alloc, .Second);
}
