const std = @import("std");
const common = @import("common");

const SchematicUnitFlags = packed struct {
    enabled: bool = false,
    geared_with_x: i3 = 0,
    geared_with_y: i3 = 0,
    _padding: u1 = 0,
};

const SchematicUnit = struct {
    const Self = @This();

    char: u8,
    flags: SchematicUnitFlags,

    pub fn digit(self: Self) bool {
        return common.isDigit(self.char);
    }

    pub fn symbol(self: Self) bool {
        return !self.digit() and self.char != '.';
    }

    pub fn gear(self: Self) bool {
        return self.char == '*';
    }

    pub fn fromu8(char: u8) Self {
        return Self{
            .char = char,
            .flags = .{},
        };
    }
};

const adjacency = [8][2]i64{
    [2]i64{ 1, 0 },
    [2]i64{ -1, 0 },
    // order here matters for p2
    [2]i64{ 1, 1 },
    [2]i64{ 0, 1 },
    [2]i64{ -1, 1 },
    [2]i64{ 1, -1 },
    [2]i64{ 0, -1 },
    [2]i64{ -1, -1 },
};

pub fn solveFirst(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var schematic: common.Array2D(SchematicUnit) = undefined;

    // find index of newline to know how many chars in a line, includes the newline
    const cols = 1 + (std.mem.indexOf(u8, input, "\n") orelse unreachable);

    {
        const units = try alloc.alloc(SchematicUnit, input.len);
        defer alloc.free(units);
        const rows = units.len / cols + 1;

        for (input, units) |char, *unit| {
            unit.* = SchematicUnit.fromu8(char);
        }

        schematic = try common.Array2D(SchematicUnit).init(
            alloc,
            cols,
            rows,
        );

        @memcpy(schematic.items[0..units.len], units);
    }
    defer schematic.deinit();

    // find the ones that are enabled in final sum
    for (0..schematic.rows) |j| {
        for (0..schematic.cols - 1) |i| { // -1 to ignore the rightmost column filled with newlines
            const cur = schematic.at(i, j);

            if (!cur.symbol()) { // skip if isn't a symbol
                continue;
            }

            for (adjacency) |adj| {
                const adj_i: i64 = @as(i64, @intCast(i)) - adj[0];
                const adj_j: i64 = @as(i64, @intCast(j)) - adj[1];

                if (adj_i < 0 or adj_i >= schematic.cols or adj_j < 0 or adj_j >= schematic.rows) {
                    continue;
                }

                var adjacent = schematic.at(@intCast(adj_i), @intCast(adj_j));
                adjacent.flags.enabled = true;
            }
        }
    }

    var sum: u64 = 0;

    for (0..schematic.rows) |j| {
        var cur_number: u64 = 0;
        var cur_enabled: bool = false;

        for (0..schematic.cols - 1) |i| { // -1 to ignore the rightmost column filled with newlines
            const cur = schematic.at(i, j);
            if (cur.digit()) {
                cur_number *= 10;
                cur_number += cur.char - '0';
                cur_enabled = cur_enabled or cur.flags.enabled;
            } else {
                if (cur_enabled) {
                    sum += cur_number;
                }

                cur_number = 0;
                cur_enabled = false;
            }
        }

        if (cur_enabled) {
            sum += cur_number;
        }
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

pub fn solveSecond(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var schematic: common.Array2D(SchematicUnit) = undefined;

    // find index of newline to know how many chars in a line, includes the newline
    const cols = 1 + (std.mem.indexOf(u8, input, "\n") orelse unreachable);

    {
        const units = try alloc.alloc(SchematicUnit, input.len);
        defer alloc.free(units);
        const rows = units.len / cols + 1;

        for (input, units) |char, *unit| {
            unit.* = SchematicUnit.fromu8(char);
        }

        schematic = try common.Array2D(SchematicUnit).init(alloc, cols, rows);

        @memcpy(schematic.items[0..units.len], units);
    }
    defer schematic.deinit();

    // find all gears
    for (0..schematic.rows) |j| {
        for (0..schematic.cols - 1) |i| { // -1 to ignore the rightmost column filled with newlines
            const cur = schematic.at(i, j);

            if (!cur.gear()) { // skip if isn't a gear symbol
                continue;
            }

            var first_adj_x: ?i64 = null;
            var first_adj_y: ?i64 = null;
            // for some reason zig can't find this label...
            for (adjacency) |adj| { // adj_loop: {
                const adj_i: i64 = @as(i64, @intCast(i)) - adj[0];
                const adj_j: i64 = @as(i64, @intCast(j)) - adj[1];

                if (adj_i < 0 or adj_i >= schematic.cols or adj_j < 0 or adj_j >= schematic.rows) {
                    continue;
                }

                var adjacent = schematic.at(@intCast(adj_i), @intCast(adj_j));
                if (adjacent.digit()) {
                    if (first_adj_x == null or
                        first_adj_y.? == adj_j and first_adj_x.? == adj_i - 1) // next to previous
                    {
                        first_adj_x = adj_i;
                        first_adj_y = adj_j;
                        continue; // :adj_loop;
                    }

                    adjacent.flags.enabled = true;
                    adjacent.flags.geared_with_x = @intCast(first_adj_x.? - adj_i);
                    adjacent.flags.geared_with_y = @intCast(first_adj_y.? - adj_j);
                    break;
                }
            }
        }
    }

    var sum: u64 = 0;

    for (0..schematic.rows) |j| {
        var cur_number: u64 = 0;
        var second_number: u64 = 0;

        for (0..schematic.cols - 1) |i| { // -1 to ignore the rightmost column filled with newlines
            const cur = schematic.at(i, j);
            if (cur.digit()) {
                cur_number *= 10;
                cur_number += cur.char - '0';
                if (cur.flags.enabled) {
                    const x: usize = @intCast(@as(i64, cur.flags.geared_with_x) + @as(i64, @intCast(i)));
                    const y: usize = @intCast(@as(i64, cur.flags.geared_with_y) + @as(i64, @intCast(j)));

                    var before_x = x - 1;
                    var mul: u64 = 1;
                    while (before_x >= 0) : (before_x -= 1) {
                        const second_cur = schematic.at(before_x, y);
                        if (!second_cur.digit()) {
                            break;
                        }

                        second_number += (second_cur.char - '0') * mul;
                        mul *= 10;

                        if (before_x == 0) {
                            break;
                        }
                    }

                    for (x..schematic.cols - 1) |after_x| {
                        const second_cur = schematic.at(after_x, y);
                        if (!second_cur.digit()) {
                            break;
                        }

                        second_number *= 10;
                        second_number += second_cur.char - '0';
                    }
                }
            } else {
                sum += cur_number * second_number;
                cur_number = 0;
                second_number = 0;
            }
        }

        sum += cur_number * second_number; // if there's a number at the end
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

const expect = std.testing.expect;
const test_alloc = std.testing.allocator;
test "day 03 first star example" {
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;

    const output = try solveFirst(input, test_alloc);
    defer test_alloc.free(output);

    try expect(std.mem.eql(u8, output, "4361"));
}

test "day 03 second star example" {
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;

    const output = try solveSecond(input, test_alloc);
    defer test_alloc.free(output);

    try expect(std.mem.eql(u8, output, "467835"));
}
