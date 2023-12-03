const std = @import("std");
const common = @import("common");

const Cubes = struct {
    red_count: usize,
    green_count: usize,
    blue_count: usize,
};

const Game = struct {
    const Self = @This();
    id: usize,
    subsets: std.ArrayList(Cubes),

    pub fn init(alloc: std.mem.Allocator) Self {
        return Game{
            .id = 0,
            .subsets = std.ArrayList(Cubes).init(alloc),
        };
    }

    pub fn deinit(self: Self) void {
        self.subsets.deinit();
    }
};

fn parse_input(input: []const u8, alloc: std.mem.Allocator) !std.ArrayList(Game) {
    var result = std.ArrayList(Game).init(alloc);

    var lines = std.mem.splitAny(u8, input, "\n");

    while (lines.next()) |line| {
        // if (line.len == 0) {
        //     break; // dirty hack but it works
        // }

        const new_game: *Game = try result.addOne();
        new_game.* = Game.init(alloc);

        const ind_begin = std.mem.indexOf(u8, line, " ") orelse unreachable;
        const ind_end = std.mem.indexOf(u8, line, ":") orelse unreachable;

        const ind_str = line[ind_begin + 1 .. ind_end];
        new_game.id = try std.fmt.parseInt(u8, ind_str, 10);

        var subsets_str = std.mem.splitAny(u8, line[ind_end + 1 ..], ";");
        while (subsets_str.next()) |subset_str| {
            const new_subset: *Cubes = try new_game.subsets.addOne();
            new_subset.red_count = 0;
            new_subset.blue_count = 0;
            new_subset.green_count = 0;

            var cubes_str = std.mem.splitAny(u8, subset_str, ",");
            while (cubes_str.next()) |space_cube_str| {
                const cube_str = space_cube_str[1..];

                const cube_split = std.mem.indexOf(u8, cube_str, " ") orelse unreachable;
                const count = try std.fmt.parseInt(u8, cube_str[0..cube_split], 10);
                const color = cube_str[cube_split + 1 ..];
                if (std.mem.eql(u8, color, "red")) {
                    new_subset.red_count = count;
                }
                if (std.mem.eql(u8, color, "blue")) {
                    new_subset.blue_count = count;
                }
                if (std.mem.eql(u8, color, "green")) {
                    new_subset.green_count = count;
                }
            }
        }
    }

    return result;
}

pub fn solve_first(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var sum: u64 = 0;

    const games = try parse_input(input, alloc);
    defer {
        for (games.items) |game| {
            game.deinit();
        }

        games.deinit();
    }

    const max_allowed = Cubes{
        .red_count = 12,
        .green_count = 13,
        .blue_count = 14,
    };
    for (games.items) |game| {
        var allowed = true;
        for (game.subsets.items) |cubes| {
            allowed = allowed and
                cubes.red_count <= max_allowed.red_count and
                cubes.green_count <= max_allowed.green_count and
                cubes.blue_count <= max_allowed.blue_count;
        }

        if (allowed) {
            sum += game.id;
        }
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

pub fn solve_second(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var sum: u64 = 0;

    const games = try parse_input(input, alloc);
    defer {
        for (games.items) |game| {
            game.deinit();
        }

        games.deinit();
    }
    for (games.items) |game| {
        var min_allowed = Cubes{
            .red_count = 0,
            .green_count = 0,
            .blue_count = 0,
        };
        for (game.subsets.items) |cubes| {
            min_allowed.red_count = @max(cubes.red_count, min_allowed.red_count);
            min_allowed.green_count = @max(cubes.green_count, min_allowed.green_count);
            min_allowed.blue_count = @max(cubes.blue_count, min_allowed.blue_count);
        }
        sum += min_allowed.red_count * min_allowed.green_count * min_allowed.blue_count;
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

const expect = std.testing.expect;
test "day 02 parse input" {
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    ;

    const output = try parse_input(input, std.testing.allocator);

    defer {
        for (output.items) |game| {
            game.deinit();
        }

        output.deinit();
    }

    try expect(output.items[0].id == 1);
    try expect(output.items[0].subsets.items[0].red_count == 4);
    try expect(output.items[0].subsets.items[0].blue_count == 3);
    try expect(output.items[0].subsets.items[1].red_count == 1);
    try expect(output.items[0].subsets.items[1].green_count == 2);
    try expect(output.items[0].subsets.items[1].blue_count == 6);
    try expect(output.items[0].subsets.items[2].green_count == 2);
}

test "day 02 first star example" {
    const alloc = std.testing.allocator;
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    const output = try solve_first(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "8"));
}

test "day 02 second star example" {
    const alloc = std.testing.allocator;
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    const output = try solve_second(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "2286"));
}
