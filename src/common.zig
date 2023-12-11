const std = @import("std");

pub fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}

pub fn isWhitespace(char: u8) bool {
    return char != ' ' and char != '\n' and char != '\r' and char != '\t';
}

pub fn Array2D(comptime element: type) type {
    return struct {
        const Self = @This();

        items: []element,
        cols: usize,
        rows: usize,
        alloc: std.mem.Allocator,

        pub fn init(
            alloc: std.mem.Allocator,
            cols: usize,
            rows: usize,
        ) !Self {
            var result = Self{
                .items = undefined,
                .cols = cols,
                .rows = rows,
                .alloc = alloc,
            };

            result.items = try result.alloc.alloc(element, cols * rows);

            return result;
        }

        pub fn deinit(self: Self) void {
            self.alloc.free(self.items);
        }

        pub fn at(self: Self, column: usize, row: usize) *element {
            return &self.items[row * self.cols + column];
        }

        pub fn rowSlice(self: Self, row: usize) []element {
            return self.items[row * self.cols .. row * self.cols + self.cols];
        }
    };
}

pub const Direction = packed struct {
    // Order matters for opposite sides
    top: bool = false,
    left: bool = false,
    right: bool = false,
    bottom: bool = false,
};
