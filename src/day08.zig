const common = @import("common");
const std = @import("std");

const Path = struct {
    from: [3]u8,
    left: [3]u8,
    right: [3]u8,
};

const Input = struct {
    instructions: []u8,
    paths: []Path,
};

fn parseInput(input: []const u8, alloc: std.mem.Allocator) !Input {
    var result = Input{
        .instructions = &[_]u8{},
        .paths = &[_]Path{},
    };
    var lines = std.mem.splitAny(u8, input, "\n");
    if (lines.next()) |line| { // instruction line
        result.instructions = try alloc.alloc(u8, line.len);
        @memcpy(result.instructions, line);
    }

    std.debug.assert(lines.next() != null); // empty line

    var paths = std.ArrayList(Path).init(alloc);
    defer paths.deinit();

    while (lines.next()) |line| {
        const from = line[0..3];
        const left = line[7..10];
        const right = line[12..15];

        (try paths.addOne()).* = Path{
            .from = [3]u8{ from[0], from[1], from[2] },
            .left = [3]u8{ left[0], left[1], left[2] },
            .right = [3]u8{ right[0], right[1], right[2] },
        };
    }

    result.paths = try paths.toOwnedSlice();

    return result;
}

const expect = std.testing.expect;
test "day 08 parse input test" {
    const alloc = std.testing.allocator;
    const input =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;

    const output = try parseInput(input, alloc);
    defer alloc.free(output.paths);
    defer alloc.free(output.instructions);

    try expect(std.mem.eql(u8, output.instructions, "LLR"));
    const expected_paths = [_]Path{
        Path{ .from = [3]u8{ 'A', 'A', 'A' }, .left = [3]u8{ 'B', 'B', 'B' }, .right = [3]u8{ 'B', 'B', 'B' } },
        Path{ .from = [3]u8{ 'B', 'B', 'B' }, .left = [3]u8{ 'A', 'A', 'A' }, .right = [3]u8{ 'Z', 'Z', 'Z' } },
        Path{ .from = [3]u8{ 'Z', 'Z', 'Z' }, .left = [3]u8{ 'Z', 'Z', 'Z' }, .right = [3]u8{ 'Z', 'Z', 'Z' } },
    };
    for (output.paths, expected_paths) |got, exp| {
        try expect(std.mem.eql(u8, &got.from, &exp.from));
        try expect(std.mem.eql(u8, &got.left, &exp.left));
        try expect(std.mem.eql(u8, &got.right, &exp.right));
    }
}

pub fn solveFirst(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const parsed = try parseInput(input, alloc);
    defer alloc.free(parsed.paths);
    defer alloc.free(parsed.instructions);

    var paths = std.StringHashMap(struct { left: [3]u8, right: [3]u8 }).init(alloc);
    defer paths.deinit();

    for (parsed.paths) |*path| {
        try paths.put(&path.from, .{ .left = path.left, .right = path.right });
    }

    var count: usize = 0;
    var cur_node = [3]u8{ 'A', 'A', 'A' };
    var cur_ins: usize = 0;
    while (!std.mem.eql(u8, &cur_node, "ZZZ")) {
        const path = paths.get(&cur_node).?;
        switch (parsed.instructions[cur_ins]) {
            'L' => cur_node = path.left,
            'R' => cur_node = path.right,
            else => unreachable,
        }

        count += 1;
        cur_ins = (cur_ins + 1) % parsed.instructions.len;
    }

    return try std.fmt.allocPrint(alloc, "{d}", .{count});
}

test "day 08 first star example" {
    const alloc = std.testing.allocator;
    const input =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;

    const output = try solveFirst(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "6"));
}

pub fn solveSecond(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const parsed = try parseInput(input, alloc);
    defer alloc.free(parsed.paths);
    defer alloc.free(parsed.instructions);

    var paths = std.StringHashMap(struct { left: [3]u8, right: [3]u8 }).init(alloc);
    defer paths.deinit();

    var cur_nodes = std.ArrayList(struct {
        node: [3]u8,
    }).init(alloc);
    defer cur_nodes.deinit();

    for (parsed.paths) |*path| {
        try paths.put(&path.from, .{ .left = path.left, .right = path.right });
        if (path.from[2] == 'A') {
            const node = try cur_nodes.addOne();
            @memcpy(&node.node, &path.from);
        }
    }

    var lcm: usize = 1;
    for (cur_nodes.items) |*cur_node| {
        var count: usize = 0;
        var cur_ins: usize = 0;

        while (cur_node.node[2] != 'Z') {
            const path = paths.get(&cur_node.node).?;
            switch (parsed.instructions[cur_ins]) {
                'L' => cur_node.node = path.left,
                'R' => cur_node.node = path.right,
                else => unreachable,
            }

            count += 1;
            cur_ins = (cur_ins + 1) % parsed.instructions.len;
        }

        lcm = lcm * count / std.math.gcd(count, lcm);
    }

    return try std.fmt.allocPrint(alloc, "{d}", .{lcm});
}

test "day 08 second star example" {
    const alloc = std.testing.allocator;
    const input =
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ;

    const output = try solveSecond(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "6"));
}
