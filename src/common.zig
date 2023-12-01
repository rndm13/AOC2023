const std = @import("std");

pub fn is_digit(char: u8) bool {
    return char >= '0' and char <= '9';
}

test "is digit" {
    try std.testing.expect(is_digit('3'));
    try std.testing.expect(is_digit('6'));
    try std.testing.expect(!is_digit('a'));
    try std.testing.expect(is_digit('0'));
    try std.testing.expect(is_digit('9'));
}
