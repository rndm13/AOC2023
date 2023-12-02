const std = @import("std");
const common = @import("common");

// kinda want to have a similar interface for every solution,
// that's why this one returns a string and not a number
pub fn solve_first(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var sum = @as(u64, 0);

    var lines = std.mem.splitAny(u8, input, "\n");
    while (lines.next()) |line| {
        var ind: ?usize = null;
        var first = @as(u64, 0);
        var last = @as(u64, 0);

        ind = std.mem.indexOfAny(u8, line, "123456789");
        if (ind == null) {
            break;
        }
        first = line[ind.?] - '0';

        ind = std.mem.lastIndexOfAny(u8, line, "123456789");
        last = line[ind.?] - '0';

        sum += first * 10 + last;
    }

    return try std.fmt.allocPrint(alloc, "{d}", .{sum});
    // should be freed yourself >:)
    // proper solution would probably be to instead of passing allocator as an argument
    // you give a buffer for writing but I am too lazy
}

// Well this is going to be funny because there aren't regexes in zig std rn
// I feel like best solution would be to use smth like trie but that will take a bit of time to implement

const found_text_number = struct {
    index: usize,
    number: u8,
};

fn find_text_number(input: []const u8, start_pos: usize) ?found_text_number {
    var result: found_text_number = .{ .index = input.len, .number = 255 };
    var ind: usize = 0;
    var numbers = [9][]const u8{
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
    };

    // searches for numbers
    ind = std.mem.indexOfAnyPos(u8, input, start_pos, "123456789") orelse input.len;
    if (result.index > ind) {
        result.index = ind;
        result.number = input[ind] - '0';
    }

    // searches for text numbers
    for (numbers, 1..10) |value, numb| {
        const u8_numb: u8 = @intCast(numb);
        ind = std.mem.indexOfPos(u8, input, start_pos, value) orelse input.len;

        if (result.index > ind) {
            result.index = ind;
            result.number = u8_numb;
        }
    }

    if (result.index == input.len) {
        return null;
    }
    return result;
}

pub fn solve_second(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var sum = @as(u64, 0);

    var lines = std.mem.splitAny(u8, input, "\n");
    while (lines.next()) |line| {
        var first: u64 = 0;
        var last: u64 = 0;

        var number: ?found_text_number = find_text_number(line, 0);
        if (number != null) {
            first = number.?.number;
        }
        while (number != null) {
            last = number.?.number;

            number = find_text_number(line, number.?.index + 1);
        }

        sum += first * 10 + last;
    }

    return try std.fmt.allocPrint(alloc, "{d}", .{sum});
}

const expect = std.testing.expect;
test "day 01 first star example" {
    const alloc = std.testing.allocator;
    const input =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;

    const output = try solve_first(input, std.testing.allocator);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "142"));
}

test "day01 find_text_number" {
    const input =
        \\nine1two
    ;

    const first = find_text_number(input, 0);

    try expect(first.?.index == 0);
    try expect(first.?.number == 9);

    const second = find_text_number(input, first.?.index + 1);
    // std.debug.print("{any}", .{second});
    try expect(second.?.index == 4);
    try expect(second.?.number == 1);

    const third = find_text_number(input, second.?.index + 1);
    try expect(third.?.index == 5);
    try expect(third.?.number == 2);
}

test "day 01 second star example" {
    const alloc = std.testing.allocator;
    const input =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;

    const output = try solve_second(input, std.testing.allocator);
    defer alloc.free(output);

    // std.debug.print("{s}\n", .{output});
    try expect(std.mem.eql(u8, output, "281"));
}
