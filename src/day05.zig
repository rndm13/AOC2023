const std = @import("std");
const common = @import("common");

const Range = struct {
    const Self = @This();
    start: i64,
    len: i64,

    fn end(self: Self) i64 {
        return self.start + self.len;
    }

    fn index(self: Self, point: i64) ?i64 {
        if (point < self.start or point >= self.end()) {
            return null;
        }

        return point - self.start;
    }
};

const RangeMapping = struct {
    const Self = @This();

    destination_range_start: i64,
    source_range_start: i64,
    range_length: i64,

    fn get(self: Self, point: i64) ?i64 {
        if (point < self.source_range_start or point >= self.source_range_end()) {
            return null;
        }

        return point + self.destination_range_start - self.source_range_start;
    }

    fn destination_range_end(self: Self) i64 {
        return self.destination_range_start + self.range_length;
    }

    fn source_range_end(self: Self) i64 {
        return self.source_range_start + self.range_length;
    }

    fn destination(self: Self) Range {
        return Range{
            .start = self.destination_range_start,
            .len = self.range_length,
        };
    }

    fn source(self: Self) Range {
        return Range{
            .start = self.source_range_start,
            .len = self.range_length,
        };
    }
};

const expect = std.testing.expect;
test "RangeMapping.get() test" {
    const elem = RangeMapping{
        .destination_range_start = 50,
        .source_range_start = 98,
        .range_length = 2,
    };

    try expect(elem.get(98) == 50);
    try expect(elem.get(99) == 51);
    try expect(elem.get(5) == null);
    try expect(elem.get(46) == null);
}

fn getFromMap(source: i64, map: []const RangeMapping) i64 {
    var mapped = source;
    for (map) |mapping| {
        const dest = mapping.get(source);
        if (dest != null) {
            mapped = mapping.get(source) orelse mapped;
        }
    }

    return mapped;
}

test "getFromMap() test" {
    const maps = [_]RangeMapping{
        RangeMapping{
            .destination_range_start = 50,
            .source_range_start = 98,
            .range_length = 2,
        },
        RangeMapping{
            .destination_range_start = 52,
            .source_range_start = 50,
            .range_length = 48,
        },
    };

    try expect(getFromMap(0, &maps) == 0);
    try expect(getFromMap(1, &maps) == 1);
    try expect(getFromMap(50, &maps) == 52);
    try expect(getFromMap(51, &maps) == 53);
    try expect(getFromMap(97, &maps) == 99);
    try expect(getFromMap(98, &maps) == 50);
    try expect(getFromMap(99, &maps) == 51);
}

fn parseMapping(input: []const u8, result: *RangeMapping) !void {
    var numbers = std.mem.splitAny(u8, input, " ");
    if (numbers.next()) |num| {
        result.destination_range_start = try std.fmt.parseInt(i64, num, 10);
    }
    if (numbers.next()) |num| {
        result.source_range_start = try std.fmt.parseInt(i64, num, 10);
    }
    if (numbers.next()) |num| {
        result.range_length = try std.fmt.parseInt(i64, num, 10);
    }
}

test "parseMapping test" {
    const input =
        \\88 18 7
    ;

    var mapping = RangeMapping{
        .destination_range_start = 0,
        .source_range_start = 0,
        .range_length = 0,
    };

    try parseMapping(input, &mapping);

    try expect(mapping.destination_range_start == 88);
    try expect(mapping.source_range_start == 18);
    try expect(mapping.range_length == 7);
}

const assert = std.debug.assert;
fn parseMap(input: []const u8, result: *std.ArrayList(RangeMapping)) !void {
    var lines = std.mem.splitAny(u8, input, "\n");
    assert(lines.next() != null); // skip over first line with just text

    while (lines.next()) |line| {
        const mapping = try result.addOne();
        try parseMapping(line, mapping);
    }
}

test "parseMap test" {
    const alloc = std.testing.allocator;
    const input =
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
    ;

    var mappings = std.ArrayList(RangeMapping).init(alloc);
    defer mappings.deinit();

    try parseMap(input, &mappings);

    try expect(mappings.items[0].destination_range_start == 88);
    try expect(mappings.items[0].source_range_start == 18);
    try expect(mappings.items[0].range_length == 7);
    try expect(mappings.items[1].destination_range_start == 18);
    try expect(mappings.items[1].source_range_start == 25);
    try expect(mappings.items[1].range_length == 70);
}

const Input = struct {
    const Self = @This();
    seeds: std.ArrayList(i64), // p1
    seed_ranges: std.ArrayList(Range), // p2

    map_pipeline: std.ArrayList(std.ArrayList(RangeMapping)),

    fn getMapPipelined(self: Self, seed: i64) i64 {
        var mapped = seed;
        for (self.map_pipeline.items) |map| {
            mapped = getFromMap(mapped, map.items);
        }

        return mapped;
    }

    fn pipelineSeedRanges(self: *Self) !void {
        for (self.map_pipeline.items) |map| {
            try mapSeedRanges(&self.seed_ranges, map.items);
            for (self.seed_ranges.items) |seed_range| {
                std.debug.print("{d} - {d}\n", .{ seed_range.start, seed_range.end() - 1 });
            }
            std.debug.print("\n-------\n\n", .{});
        }
    }

    fn init(alloc: std.mem.Allocator) Self {
        return .{
            .seeds = std.ArrayList(i64).init(alloc),
            .seed_ranges = std.ArrayList(Range).init(alloc),
            .map_pipeline = std.ArrayList(std.ArrayList(RangeMapping)).init(alloc),
        };
    }

    fn deinit(self: Self) void {
        for (self.map_pipeline.items) |map| {
            map.deinit();
        }
        self.map_pipeline.deinit();
        self.seeds.deinit();
        self.seed_ranges.deinit();
    }
};

fn parseInput(input: []const u8, result: *Input) !void {
    var input_groups = std.mem.splitSequence(u8, input, "\n\n");

    if (input_groups.next()) |seeds| { // first line contains only seeds
        var numbers = std.mem.splitAny(u8, seeds, " ");
        assert(numbers.next() != null); // remove unnecessary stuff
        while (numbers.next()) |num| {
            const seed = try result.seeds.addOne();
            seed.* = try std.fmt.parseInt(i64, num, 10);
        }
    }

    while (input_groups.next()) |map| {
        const new_map = try result.map_pipeline.addOne();
        new_map.* = std.ArrayList(RangeMapping).init(result.map_pipeline.allocator);
        try parseMap(map, new_map);
    }
}

pub fn solveFirst(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var parsed_input = Input.init(alloc);
    defer parsed_input.deinit();

    try parseInput(input, &parsed_input);

    var min: i64 = 99999999999999; // idk, some large number, didn't find something like i64max
    for (parsed_input.seeds.items) |seed| {
        min = @min(parsed_input.getMapPipelined(seed), min);
    }

    return std.fmt.allocPrint(alloc, "{d}", .{min});
}

fn mapSeedRanges(seed_ranges: *std.ArrayList(Range), map: []const RangeMapping) !void {
    // Abbomination of a function
    // I got very angry so I just decided to try and explicitly handle every case I could think of
    // At least it has nice comments I think

    var results = std.ArrayList(Range).init(seed_ranges.allocator);
    defer results.deinit();
    var next_ranges = std.ArrayList(Range).init(seed_ranges.allocator);
    defer next_ranges.deinit();
    try next_ranges.insertSlice(next_ranges.items.len, seed_ranges.items);
    for (map) |mapping_range| {
        const ranges = try next_ranges.toOwnedSlice();
        defer next_ranges.allocator.free(ranges);
        for (ranges) |range| {
            if (mapping_range.source().index(range.start) != null and mapping_range.source().index(range.end() - 1) != null) {
                // range:           ******
                // mapping_range: ----------

                const mapped = Range{
                    .start = mapping_range.get(range.start).?,
                    .len = range.len,
                };
                (try results.addOne()).* = mapped;

                continue;
            }

            var any = false;

            const left_split = range.index(mapping_range.source_range_start) orelse 0;
            if (left_split > 0) {
                // range:         **------
                // mapping_range:   ----

                const left = Range{
                    .start = range.start,
                    .len = left_split,
                };

                any = true;
                (try next_ranges.addOne()).* = left;
            }

            const right_split = range.index(mapping_range.source_range_end() - 1) orelse range.len - 1;

            if (range.index(mapping_range.source_range_start) != null or range.index(mapping_range.source_range_end() - 1) != null) {
                // range:         --****--
                // mapping_range:   ----

                const middle = Range{
                    .start = mapping_range.get(range.start + left_split).?,
                    .len = right_split + 1 - left_split,
                };

                any = true;
                (try results.addOne()).* = middle;
            }

            const right = Range{
                .start = range.start + right_split + 1,
                .len = range.len - (right_split + 1),
            };

            if (right.len > 0) {
                // range:         ------**
                // mapping_range:   ----
                any = true;
                (try next_ranges.addOne()).* = right;
            }

            if (!any) {
                (try next_ranges.addOne()).* = range;
            }
        }
    }

    try seed_ranges.resize(0);
    try seed_ranges.insertSlice(seed_ranges.items.len, next_ranges.items);
    try seed_ranges.insertSlice(seed_ranges.items.len, results.items);
}

test "mapSeedRanges middle test" {
    const alloc = std.testing.allocator;
    var seed_ranges = std.ArrayList(Range).init(alloc);
    defer seed_ranges.deinit();
    try seed_ranges.insertSlice(seed_ranges.items.len, &[_]Range{
        Range{
            .start = 2,
            .len = 10,
        },
    });

    const map = [_]RangeMapping{
        RangeMapping{
            .source_range_start = 7,
            .destination_range_start = 15,
            .range_length = 1,
        },
    };

    try mapSeedRanges(&seed_ranges, &map);

    const expected_seeds = [_]Range{
        Range{
            .start = 2,
            .len = 5,
        },
        Range{
            .start = 8,
            .len = 4,
        },
        Range{
            .start = 15,
            .len = 1,
        },
    };

    for (seed_ranges.items, expected_seeds) |got, expected| {
        // std.debug.print("{} - {} = {} - {}\n", .{ got.start, got.end(), expected.start, expected.end() });
        try expect(got.start == expected.start);
        try expect(got.len == expected.len);
    }
}

pub fn solveSecond(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var parsed_input = Input.init(alloc);
    defer parsed_input.deinit();

    try parseInput(input, &parsed_input);

    var seed_pairs = std.mem.window(i64, parsed_input.seeds.items, 2, 2);

    while (seed_pairs.next()) |seed_pair| {
        (try parsed_input.seed_ranges.addOne()).* = Range{
            .start = seed_pair[0],
            .len = seed_pair[1],
        };
    }

    try parsed_input.pipelineSeedRanges();

    var min = parsed_input.seed_ranges.items[0].start;
    for (parsed_input.seed_ranges.items) |seeds| {
        min = @min(min, seeds.start);
    }

    return std.fmt.allocPrint(alloc, "{d}", .{min});
}

test "day 05 first star example" {
    const alloc = std.testing.allocator;
    const input =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;

    const output = try solveFirst(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "35"));
}

test "day 05 second star example" {
    const alloc = std.testing.allocator;
    const input =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;

    const output = try solveSecond(input, alloc);

    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "46"));
}
