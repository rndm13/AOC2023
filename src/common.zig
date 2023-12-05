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
        alloc: std.mem.Allocator,

        pub fn init(
            alloc: std.mem.Allocator,
            elements: []const element,
            cols: usize,
        ) !Self {
            var result = Self{
                .items = undefined,
                .cols = cols,
                .alloc = alloc,
            };

            result.items = try result.alloc.alloc(element, elements.len);
            @memcpy(result.items, elements);

            return result;
        }

        pub fn deinit(self: Self) void {
            self.alloc.free(self.items);
        }

        pub fn at(self: Self, column: usize, row: usize) *element {
            return &self.items[row * self.cols + column];
        }

        pub fn rows(self: Self) usize {
            return self.items.len / self.cols + 1;
        }

        pub fn rowsIterator(self: Self) std.mem.WindowIterator(element) {
            std.mem.window(element, self.items, self.cols, self.cols);
        }
    };
}
