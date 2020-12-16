const std = @import("std");
const starting_numbers = [_]u32{ 0, 14, 6, 20, 1, 4 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    std.debug.print("Part 1: {}\n", .{try findNthNumber(allocator, 2020)});
    std.debug.print("Part 2: {}\n", .{try findNthNumber(allocator, 30000000)});
}

// I was so tired when writing this. I might come back to it later.
fn findNthNumber(allocator: *std.mem.Allocator, max_turn: u32) !u32 {
    const NumInfo = struct { lastTurnSpoken: u32 = 0, prevTurnSpoken: u32 = 0 };
    var numbers = std.AutoArrayHashMap(u32, NumInfo).init(allocator);
    defer numbers.deinit();

    for (starting_numbers) |number, i| {
        const turn = @intCast(u32, i + 1);
        try numbers.put(number, .{ .lastTurnSpoken = turn });
    }

    var turn: u32 = starting_numbers.len + 1;
    var last_spoken: u32 = starting_numbers[starting_numbers.len - 1];

    while (turn <= max_turn) : (turn += 1) {
        if (numbers.getEntry(last_spoken)) |entry| {
            const num_info = entry.value;

            if (num_info.prevTurnSpoken == 0) {
                last_spoken = 0;
            } else {
                last_spoken = num_info.lastTurnSpoken - num_info.prevTurnSpoken;
            }
        } else {
            last_spoken = 0;
        }

        const num_info = &(try numbers.getOrPutValue(last_spoken, .{})).value;
        num_info.prevTurnSpoken = num_info.lastTurnSpoken;
        num_info.lastTurnSpoken = turn;
    }

    return last_spoken;
}
