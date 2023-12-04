const std = @import("std");
const common = @import("common");

fn parseNumbers(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const count = input.len / 3;
    const result = try alloc.alloc(u8, count);
    var numbers = std.mem.window(u8, input, 3, 3);
    while (numbers.next()) |number| {
        const i = (numbers.index orelse input.len) / 3 - 1;

        result[i] = try std.fmt.parseInt(u8, std.mem.trimLeft(u8, number, " "), 10);
    }

    return result;
}

const ScratchCard = struct {
    const Self = @This();

    winning: []const u8,
    your: []const u8,

    count: u64 = 1, // part 2

    fn match_count(self: Self) u64 {
        var matched: u64 = 0;
        for (self.your) |hay| {
            for (self.winning) |needle| {
                if (hay == needle) {
                    matched += 1;
                }
            }
        }

        return matched;
    }
};

fn parse_input(input: []const u8, alloc: std.mem.Allocator) !std.ArrayList(ScratchCard) {
    var result = std.ArrayList(ScratchCard).init(alloc);

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        const card_end = std.mem.indexOf(u8, line, ":") orelse unreachable;
        const list_split = std.mem.indexOf(u8, line, "|") orelse unreachable;
        const winning_str = line[card_end + 1 .. list_split - 1];
        const your_str = line[list_split + 1 ..];

        const card = try result.addOne();
        card.* = ScratchCard{
            .winning = try parseNumbers(winning_str, alloc),
            .your = try parseNumbers(your_str, alloc),
        };
    }

    return result;
}

pub fn solve_first(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const parsed = try parse_input(input, alloc);
    defer {
        for (parsed.items) |card| {
            alloc.free(card.winning);
            alloc.free(card.your);
        }
        parsed.deinit();
    }

    var sum: u64 = 0;

    for (parsed.items) |card| {
        const count = card.match_count();

        if (count <= 0) {
            continue;
        }

        sum += try std.math.powi(u64, 2, count - 1);
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

pub fn solve_second(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const parsed = try parse_input(input, alloc);

    defer {
        for (parsed.items) |card| {
            alloc.free(card.winning);
            alloc.free(card.your);
        }
        parsed.deinit();
    }

    var sum: u64 = 0;

    for (0..parsed.items.len) |i| {
        const card = parsed.items[i];
        // std.debug.print("{d} = {d}\n", .{ i, card.count });

        sum += card.count;
        const match = card.match_count();

        for (i + 1..i + match + 1) |j| {
            if (j >= parsed.items.len) { // edge case when you get cards that are not in input
                // std.debug.print("{d} = {d}\n", .{ j, card.count });
                sum += card.count;
                continue;
            }

            parsed.items[j].count += card.count;
        }
    }

    return std.fmt.allocPrint(alloc, "{d}", .{sum});
}

const expect = std.testing.expect;
test "day 04 first star example" {
    const alloc = std.testing.allocator;
    const input =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;

    const output = try solve_first(input, std.testing.allocator);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "13"));
}

test "day 04 second star example" {
    const alloc = std.testing.allocator;
    const input =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;

    const output = try solve_second(input, std.testing.allocator);
    defer alloc.free(output);

    std.debug.print("{s}\n", .{output});
    try expect(std.mem.eql(u8, output, "30"));
}
