const std = @import("std");
const my_input = @embedFile("input/10");

const asc_u32 = std.sort.asc(u32);

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var adapters = std.ArrayList(u32).init(allocator);
    try adapters.append(0);

    var line_iter = std.mem.tokenize(my_input, "\n");

    while (line_iter.next()) |line| {
        try adapters.append(
            try std.fmt.parseUnsigned(u32, line, 10),
        );
    }

    std.sort.sort(u32, adapters.items, {}, asc_u32);

    var one_jolt_differences: u32 = 0;
    var three_jolt_differences: u32 = 0;

    for (adapters.items[1..]) |adapter, i| {
        const difference = adapter - adapters.items[i];

        one_jolt_differences += @boolToInt(difference == 1);
        three_jolt_differences += @boolToInt(difference == 3);
    }

    // Bult-in adapter is always rated for 3 jolts higher
    three_jolt_differences += 1;

    std.debug.print("Part 1: {}\n", .{
        one_jolt_differences * three_jolt_differences,
    });

    var combinations: u64 = 1;

    var occurences = try allocator.alloc(u64, adapters.items.len);
    std.mem.set(u64, occurences, 0);
    occurences[0] = 1;

    for (adapters.items) |adapter, i| {
        var possible_paths: u32 = 0;

        var j: usize = 1;
        while (i + j < adapters.items.len and j <= 3) : (j += 1) {
            if (adapters.items[i + j] - adapter <= 3) {
                occurences[i + j] += occurences[i];
                possible_paths += 1;
            } else break;
        }

        if (possible_paths > 0) {
            combinations += (possible_paths - 1) * occurences[i];
        }
    }

    std.debug.print("Part 2: {}\n", .{combinations});
}
