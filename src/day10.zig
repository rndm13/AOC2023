const common = @import("common");
const std = @import("std");

const expect = std.testing.expect;

const Color = enum(u2) {
    None = 0,

    Processing = 1,
    Processed = 2,
};

const Pipe = struct {
    const Self = @This();

    symbol: u8,

    data: packed struct {
        color: Color = .None,
        loop: bool = false,
        connections: common.Direction,
    },

    fn init(symbol: u8) Self {
        const connections = switch (symbol) {
            'S' => common.Direction{ .left = true, .right = true, .top = true, .bottom = true },
            '|' => common.Direction{ .top = true, .bottom = true },
            '-' => common.Direction{ .left = true, .right = true },
            'L' => common.Direction{ .top = true, .right = true },
            'F' => common.Direction{ .bottom = true, .right = true },
            'J' => common.Direction{ .top = true, .left = true },
            '7' => common.Direction{ .left = true, .bottom = true },
            '.' => common.Direction{},
            else => {
                std.debug.print("'{c}'", .{symbol});
                unreachable;
            },
        };

        return Self{
            .symbol = symbol,
            .data = .{ .connections = connections },
        };
    }
};

fn parsePipeline(input: []const u8, alloc: std.mem.Allocator) !common.Array2D(Pipe) {
    const cols = std.mem.indexOf(u8, input, "\n").?;
    const rows = (input.len + 1) / (cols + 1);
    const result = try common.Array2D(Pipe).init(alloc, cols, rows);

    var lines = std.mem.splitAny(u8, input, "\n");
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        for (line, 0..) |sym, j| {
            result.at(j, i).* = Pipe.init(sym);
        }
    }

    return result;
}

test "day 10 parse input" {
    const alloc = std.testing.allocator;
    const input =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    const output = try parsePipeline(input, alloc);
    defer output.deinit();
}

const BfsResult = struct {
    distance: usize,
    coords: @Vector(2, usize),
};

fn adjacentCoords(coords: @Vector(2, usize), comptime dir: usize) @Vector(2, usize) {
    return coords -% @Vector(2, usize){ 1, 1 } +% comptime switch (dir) {
        0 => @Vector(2, usize){ 1, 0 }, // top
        1 => @Vector(2, usize){ 0, 1 }, // left
        2 => @Vector(2, usize){ 2, 1 }, // right
        3 => @Vector(2, usize){ 1, 2 }, // bottom
        else => unreachable,
    };
}

fn bfs(pipeline: common.Array2D(Pipe)) !BfsResult {
    const alloc: std.mem.Allocator = pipeline.alloc;
    var queue = try std.ArrayList(@Vector(2, usize)).initCapacity(alloc, pipeline.cols * pipeline.rows / 4);
    defer queue.deinit();

    start: for (0..pipeline.cols) |i| {
        for (0..pipeline.rows) |j| {
            if (pipeline.at(i, j).symbol == 'S') {
                pipeline.at(i, j).data.color = .Processing;
                (try queue.addOne()).* = .{ i, j };
                break :start;
            }
        }
    }

    var i: usize = 0;
    var len: usize = 1;
    while (i < len) : (i += 1) {
        const coords = queue.items[i];

        const pipe = pipeline.at(coords[0], coords[1]);

        const connections = pipe.data.connections;
        // iterate through all dirs
        inline for (0..dirs.Struct.fields.len) |dir| {
            const field = dirs.Struct.fields[dir];
            const op_field = dirs.Struct.fields[dirs.Struct.fields.len - 1 - dir];
            const name = field.name;
            const op_name = op_field.name;
            const value = @field(connections, name);

            // unfortunately zig as of right now (2023-12-10) doesn't allow for control flow (continue) in inline for so I need to write it like so
            if (value) {
                const adj_coords = adjacentCoords(coords, dir);
                if (@reduce(.Max, adj_coords) < pipeline.cols) { // cols == rows in inputs
                    const connected_pipe = pipeline.at(adj_coords[0], adj_coords[1]);
                    // std.debug.print("{s}\n{c} {any}\n{c} {any}\n\n", .{ name, pipe.symbol, pipe, connected_pipe.symbol, connected_pipe });
                    if (connected_pipe.data.color != .Processed) {
                        const op_value = @field(connected_pipe.data.connections, op_name);
                        if (op_value) {
                            if (connected_pipe.data.color == .Processing) {
                                return .{ .distance = queue.items.len / 2, .coords = adj_coords };
                            }

                            connected_pipe.data.color = .Processing;

                            (try queue.addOne()).* = adj_coords;
                            len += 1;
                        }
                    }
                }
            }
        }
        pipe.data.color = .Processed;
    }

    return error{NotFound}.NotFound;
}

pub fn solveFirst(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var pipelines = try parsePipeline(input, alloc);
    defer pipelines.deinit();

    const result = try bfs(pipelines);
    return std.fmt.allocPrint(alloc, "{d}", .{result.distance});
}

test "day 10 first star" {
    const alloc = std.testing.allocator;
    const input =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    const output = try solveFirst(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "8"));
}

const dirs = @typeInfo(common.Direction);
fn outline(pipeline: common.Array2D(Pipe), start: @Vector(2, usize)) void {
    var last_saved: usize = 0;
    var connected = [3]?@Vector(2, usize){ start, null, null };

    var i: usize = 0;
    while (true) : (i = (i + 1) % connected.len) {
        const coords = connected[i].?;
        const pipe = pipeline.at(coords[0], coords[1]);

        pipe.data.loop = true;
        if (pipe.symbol == 'S') {
            // remove unused connections from S

            inline for (0..dirs.Struct.fields.len) |dir| {
                const field = dirs.Struct.fields[dir];
                const name = field.name;
                const op_field = dirs.Struct.fields[dirs.Struct.fields.len - 1 - dir];
                const op_name = op_field.name;
                const value = @field(pipe.data.connections, name);

                if (value) {
                    const adj_coords = adjacentCoords(coords, dir);

                    const connected_pipe = pipeline.at(adj_coords[0], adj_coords[1]);
                    const op_value = @field(connected_pipe.data.connections, op_name);

                    if (!connected_pipe.data.loop or !op_value) {
                        @field(pipe.data.connections, name) = false;
                    }
                }
            }

            break;
        }

        const connections = pipe.data.connections;
        // iterate through all dirs
        inline for (0..dirs.Struct.fields.len) |dir| {
            const field = dirs.Struct.fields[dir];
            const name = field.name;
            const value = @field(connections, name);

            if (value) {
                const adj_coords = adjacentCoords(coords, dir);
                const connected_pipe = pipeline.at(adj_coords[0], adj_coords[1]);
                if (!connected_pipe.data.loop) {
                    last_saved = (last_saved + 1) % connected.len;
                    connected[last_saved] = adj_coords;
                }
            }
        }
    }

    for (connected) |coord| {
        pipeline.at(coord.?[0], coord.?[1]).data.loop = true;
    }
}

pub fn solveSecond(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var pipelines = try parsePipeline(input, alloc);
    defer pipelines.deinit();

    const result = try bfs(pipelines);
    outline(pipelines, result.coords);

    var count: usize = 0;
    for (0..pipelines.rows) |row| {
        var inside = false;
        var turns: ?i64 = null;
        for (0..pipelines.cols) |col| {
            const pipe = pipelines.at(col, row);

            if (!pipe.data.loop) {
                count += @intFromBool(inside);
                continue;
            }

            const connections = pipe.data.connections;
            if (connections.top) {
                turns = turns orelse 0;
                turns.? += 1;
            }

            if (connections.bottom) {
                turns = turns orelse 0;
                turns.? -= 1;
            }

            if (turns == 0) {
                inside = !inside;
            }

            if (turns != null and @rem(turns.?, 2) == 0) {
                turns = null;
            }
        }
        std.debug.assert(turns == null);
    }

    return std.fmt.allocPrint(alloc, "{d}", .{count});
}

test "day 10 second star" {
    const alloc = std.testing.allocator;
    const input =
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    ;
    const output = try solveSecond(input, alloc);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "8"));
}
