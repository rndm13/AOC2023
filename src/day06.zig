const common = @import("common");
const std = @import("std");

const Race = struct {
    time: u64,
    distance: u64,
};

fn parseNumbers(input: []const u8, alloc: std.mem.Allocator) ![]u64 {
    var numbers = std.ArrayList(u64).init(alloc);
    defer numbers.deinit();

    var words = std.mem.splitAny(u8, input, " ");
    while (words.next()) |word| {
        if (std.fmt.parseInt(u64, word, 10) catch null) |number| {
            (try numbers.addOne()).* = number;
        }
    }

    return numbers.toOwnedSlice();
}

fn parseInput(input: []const u8, alloc: std.mem.Allocator) ![]Race {
    var times: []u64 = undefined;
    var distances: []u64 = undefined;

    var lines = std.mem.split(u8, input, "\n");
    if (lines.next()) |line| {
        // times
        const numbers = line[9..];
        times = try parseNumbers(numbers, alloc);
    }
    defer alloc.free(times);

    if (lines.next()) |line| {
        // distances
        const numbers = line[9..];
        distances = try parseNumbers(numbers, alloc);
    }
    defer alloc.free(distances);

    var races = try alloc.alloc(Race, times.len);
    for (races, times, distances) |*r, t, d| {
        r.time = t;
        r.distance = d;
    }

    return races;
}

const expect = std.testing.expect;
test "day06 parseInput test" {
    const alloc = std.testing.allocator;
    const input =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;
    const races = try parseInput(input, alloc);
    defer alloc.free(races);

    const expected = [_]Race{
        Race{ .time = 7, .distance = 9 },
        Race{ .time = 15, .distance = 40 },
        Race{ .time = 30, .distance = 200 },
    };

    for (races, expected) |race, exp| {
        try expect(race.distance == exp.distance);
        try expect(race.time == exp.time);
    }
}

fn getErrorMargin(race: Race) u64 {
    var min_time = (race.time - 1) / 2;
    while (min_time > 0) : (min_time -= 1) {
        const dist = min_time * (race.time - min_time);
        if (dist <= race.distance) {
            break;
        }
    }

    min_time += 1;

    const ret = ((race.time - 1) / 2 - min_time + 1) * 2 + ((race.time + 1) % 2);
    // std.debug.print("{d}\n", .{ret});
    return ret;
}

test "getErrorMargin test" {
    try expect(getErrorMargin(Race{ .time = 7, .distance = 9 }) == 4);
    try expect(getErrorMargin(Race{ .time = 15, .distance = 40 }) == 8);
    try expect(getErrorMargin(Race{ .time = 30, .distance = 200 }) == 9);
    try expect(getErrorMargin(Race{ .time = 71530, .distance = 940200 }) == 71503);
}

pub fn solveFirst(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const races = try parseInput(input, alloc);
    defer alloc.free(races);

    var prod: u64 = 1;
    for (races) |race| {
        prod *= getErrorMargin(race);
    }

    return try std.fmt.allocPrint(alloc, "{d}", .{prod});
}

fn numberDigits(num: u64) u64 {
    var sum: u64 = 0;
    var n = num;
    while (n > 0) : (n /= 10) {
        sum += 1;
    }
    return sum;
}

pub fn solveSecond(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const races = try parseInput(input, alloc);
    defer alloc.free(races);

    var race = Race{ .distance = 0, .time = 0 };
    for (races) |r| {
        race.distance *= try std.math.powi(u64, 10, numberDigits(r.distance));
        race.distance += r.distance;
        race.time *= try std.math.powi(u64, 10, numberDigits(r.time));
        race.time += r.time;
    }

    const ret = getErrorMargin(race);

    return try std.fmt.allocPrint(alloc, "{d}", .{ret});
}
