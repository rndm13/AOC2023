const std = @import("std");
const common = @import("common");

fn Star(comptime elem: type) type {
    return @Vector(2, elem);
}

fn parseInput(comptime star_bound: type, input: []const u8, alloc: std.mem.Allocator) !std.ArrayList(Star(star_bound)) {
    var result = std.ArrayList(Star(star_bound)).init(alloc);

    var cur: Star(star_bound) = @splat(0);

    for (input) |ch| {
        if (ch == '\n') {
            cur[1] += 1;
            cur[0] = 0;
            continue;
        }

        if (ch == '#') {
            try result.append(cur);
        }
        cur[0] += 1;
    }

    return result;
}

const expect = std.testing.expect;
test "day 11 parse input" {
    const alloc = std.testing.allocator;

    const input =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    const parsed = try parseInput(i16, input, alloc);
    defer parsed.deinit();
    const expected = [_]Star(i16){
        .{ 3, 0 },
        .{ 7, 1 },
        .{ 0, 2 },
        .{ 6, 4 },
        .{ 1, 5 },
        .{ 9, 6 },
        .{ 7, 8 },
        .{ 0, 9 },
        .{ 4, 9 },
    };

    for (parsed.items, expected) |p, exp| {
        try expect(@reduce(.And, p == exp));
    }
}

pub fn spaceExpansion(comptime star_bound: type, comptime expand_by: star_bound, alloc: std.mem.Allocator, points: std.ArrayList(Star(star_bound))) !void {
    var max: Star(star_bound) = @splat(0);

    for (points.items) |point| {
        max = @select(star_bound, point > max, point, max);
    }
    max += @splat(1);

    const used_cols = try alloc.alloc(bool, @intCast(max[0]));
    defer alloc.free(used_cols);
    @memset(used_cols, false);

    const used_rows = try alloc.alloc(bool, @intCast(max[1]));
    defer alloc.free(used_rows);
    @memset(used_rows, false);

    for (points.items) |point| {
        used_cols[@intCast(point[0])] = true;
        used_rows[@intCast(point[1])] = true;
    }

    for (used_cols, 0..) |col, i| {
        if (col) {
            continue;
        }

        for (points.items) |*point| {
            if (point[0] > i) {
                continue;
            }

            point[0] -= expand_by;
        }
    }

    for (used_rows, 0..) |row, i| {
        if (row) {
            continue;
        }

        for (points.items) |*point| {
            if (point[1] > i) {
                continue;
            }

            point[1] -= expand_by;
        }
    }
}

pub fn solveFirst(input: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const points = try parseInput(i16, input, alloc);
    defer points.deinit();

    try spaceExpansion(i16, 1, alloc, points);

    var sum: usize = 0;
    for (0..points.items.len) |i| {
        for (i + 1..points.items.len) |j| {
            sum +|= @reduce(.Add, @abs(points.items[i] - points.items[j]));
        }
    }
    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

test "day 11 part one" {
    const alloc = std.testing.allocator;

    const input =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    const output = try solveFirst(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "374"));
}

pub fn solveSecond(input: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const points = try parseInput(i64, input, alloc);
    defer points.deinit();

    try spaceExpansion(i64, 999_999, alloc, points);

    var sum: u64 = 0;
    for (0..points.items.len) |i| {
        for (i + 1..points.items.len) |j| {
            sum +|= @reduce(.Add, @abs(points.items[i] - points.items[j]));
        }
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}
