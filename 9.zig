const std = @import("std");
const my_input = @embedFile("input/9");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var numbers = std.ArrayList(u64).init(allocator);
    var line_iter = std.mem.tokenize(my_input, "\n");

    while (line_iter.next()) |line| {
        try numbers.append(
            try std.fmt.parseUnsigned(u64, line, 10),
        );
    }

    var invalid_number = blk: {
        var i: usize = 25;
        outer: while (i < numbers.items.len) : (i += 1) {
            for (numbers.items[i - 25 .. i]) |num1, j| {
                for (numbers.items[i - 25 .. i]) |num2, k| {
                    if (j != k and num1 + num2 == numbers.items[i]) {
                        continue :outer;
                    }
                }
            }

            break :blk numbers.items[i];
        } else std.debug.panic("All numbers are valid!\n", .{});
    };

    std.debug.print("Part 1: {}\n", .{invalid_number});

    var first: usize = 0;
    var last: usize = 0;
    var sum: u64 = 0;

    while (first < numbers.items.len) : (first += 1) {
        last = first;
        sum = 0;

        while (sum < invalid_number) : (last += 1) {
            sum += numbers.items[last];
        }

        if (sum == invalid_number) break;
    }

    var min = std.mem.min(u64, numbers.items[first..last]);
    var max = std.mem.max(u64, numbers.items[first..last]);

    var encryption_weakness = min + max;

    std.debug.print("Part 2: {}\n", .{encryption_weakness});
}
