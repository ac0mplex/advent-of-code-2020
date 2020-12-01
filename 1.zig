const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const file_content = try std.fs.cwd().readFileAlloc(
        allocator,
        "input/1",
        std.math.maxInt(usize),
    );

    var numbers = std.ArrayList(u32).init(allocator);
    var lines = std.mem.split(file_content, "\n");

    while (lines.next()) |line| {
        // NOTE: If line is not trimmed, parseInt will return error
        if (std.fmt.parseInt(u32, line, 10)) |number| {
            try numbers.append(number);
        } else |err| {}
    }

    std.debug.print("{}\n", .{solve(numbers.items)});
    std.debug.print("{}\n", .{solve2(numbers.items)});
}

pub fn solve(items: []u32) u32 {
    for (items) |item1, i| {
        for (items[i..]) |item2| {
            if (item1 + item2 == 2020) {
                return item1 * item2;
            }
        }
    }

    return 0;
}

pub fn solve2(items: []u32) u32 {
    for (items) |item1, i| {
        for (items[i..]) |item2, j| {
            for (items[j..]) |item3| {
                if (item1 + item2 + item3 == 2020) {
                    return item1 * item2 * item3;
                }
            }
        }
    }

    return 0;
}
