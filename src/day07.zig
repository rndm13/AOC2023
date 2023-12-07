const common = @import("common");
const std = @import("std");

const HandType = enum(u8) {
    FiveOfAKind,
    FourOfAKind,
    FullHouse,
    ThreeOfAKind,
    TwoPair,
    OnePair,
    HighCard,
};

const allCards = [_]u8{ 'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2' };
const allCardsJoker = [_]u8{ 'A', 'K', 'Q', 'T', '9', '8', '7', '6', '5', '4', '3', '2', 'J' };

const Hand = struct {
    const Self = @This();

    cards: [5]u8, // index of Cards
    type: HandType,

    fn init(cards: []const u8, comptime joker: bool) Self {
        const card_set = if (joker) allCardsJoker else allCards;
        var labels = [13]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

        var result = Self{
            .cards = [5]u8{ 0, 0, 0, 0, 0 },
            .type = .HighCard,
        };

        for (cards, &result.cards) |card, *res| {
            const index = std.mem.indexOf(u8, &card_set, &[_]u8{card}).?;
            res.* = @intCast(index);
            labels[index] += 1;
        }

        var jokers: u8 = 0;
        if (joker) {
            jokers = labels[12];
            labels[12] = 0;
        }

        std.mem.sort(u8, &labels, {}, comptime std.sort.desc(u8));
        labels[0] += jokers;

        result.type = type: {
            const type_det = labels[0..5];

            if (std.mem.eql(u8, type_det, &[_]u8{ 5, 0, 0, 0, 0 })) {
                break :type .FiveOfAKind;
            }
            if (std.mem.eql(u8, type_det, &[_]u8{ 4, 1, 0, 0, 0 })) {
                break :type .FourOfAKind;
            }
            if (std.mem.eql(u8, type_det, &[_]u8{ 3, 2, 0, 0, 0 })) {
                break :type .FullHouse;
            }
            if (std.mem.eql(u8, type_det, &[_]u8{ 3, 1, 1, 0, 0 })) {
                break :type .ThreeOfAKind;
            }
            if (std.mem.eql(u8, type_det, &[_]u8{ 2, 2, 1, 0, 0 })) {
                break :type .TwoPair;
            }
            if (std.mem.eql(u8, type_det, &[_]u8{ 2, 1, 1, 1, 0 })) {
                break :type .OnePair;
            }
            break :type .HighCard;
        };

        return result;
    }
};

fn compareHands(_: void, a: Hand, b: Hand) bool {
    if (a.type != b.type) {
        return @intFromEnum(a.type) < @intFromEnum(b.type);
    }

    for (a.cards, b.cards) |card_a, card_b| {
        if (card_a != card_b) {
            return card_a < card_b;
        }
    }

    return false;
}

fn compareSets(_: void, a: Set, b: Set) bool {
    return compareHands({}, a.hand, b.hand);
}

const expect = std.testing.expect;
test "Hand test" {
    const five = Hand.init("AAAAA", false);
    try expect(std.mem.eql(u8, &five.cards, &[_]u8{ 0, 0, 0, 0, 0 }));
    try expect(five.type == .FiveOfAKind);
    const four = Hand.init("22228", false);
    try expect(std.mem.eql(u8, &four.cards, &[_]u8{ 12, 12, 12, 12, 6 }));
    try expect(four.type == .FourOfAKind);
    const four_2 = Hand.init("AAAA8", false);
    try expect(std.mem.eql(u8, &four_2.cards, &[_]u8{ 0, 0, 0, 0, 6 }));
    try expect(four_2.type == .FourOfAKind);

    var items = [_]Hand{ four, five, four_2 };

    std.mem.sort(Hand, &items, {}, compareHands);

    try expect(items[0].type == .FiveOfAKind);
    try expect(items[1].type == .FourOfAKind);
    try expect(std.mem.eql(u8, &items[1].cards, &four_2.cards));
    try expect(items[2].type == .FourOfAKind);
}

const Set = struct {
    hand: Hand,
    bid: u64,
};

fn parseLine(input: []const u8, comptime joker: bool) !Set {
    const cards = input[0..5];
    const bid = try std.fmt.parseInt(u64, input[6..], 10);

    return Set{
        .hand = Hand.init(cards, joker),
        .bid = bid,
    };
}

pub fn solve(input: []const u8, alloc: std.mem.Allocator, comptime joker: bool) ![]const u8 {
    var sets = std.ArrayList(Set).init(alloc);
    defer sets.deinit();

    var lines = std.mem.splitAny(u8, input, "\n");
    while (lines.next()) |line| {
        (try sets.addOne()).* = try parseLine(line, joker);
    }

    std.mem.sort(Set, sets.items, {}, compareSets);

    var sum: u64 = 0;
    for (sets.items, 0..) |set, i| {
        sum += set.bid * (sets.items.len - i);
    }
    return try std.fmt.allocPrint(alloc, "{}", .{sum});
}

test "Day 07 first star example" {
    const alloc = std.testing.allocator;

    const input =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;
    const output = try solve(input, alloc, false);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "6440"));
}

test "Day 07 second star example" {
    const alloc = std.testing.allocator;

    const input =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;
    const output = try solve(input, alloc, true);
    defer alloc.free(output);

    try expect(std.mem.eql(u8, output, "5905"));
}
