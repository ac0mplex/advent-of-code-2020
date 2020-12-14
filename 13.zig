const std = @import("std");
const my_input = @embedFile("input/13");

const BusID = struct {
    id: u32,
    position: u32,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var line_iter = std.mem.tokenize(my_input, "\n");

    const timestamp = try std.fmt.parseUnsigned(
        u32,
        line_iter.next().?,
        10,
    );

    var bus_ids = std.ArrayList(BusID).init(allocator);
    var token_iter = std.mem.tokenize(line_iter.next().?, ",");
    var position: u32 = 0;

    while (token_iter.next()) |token| : (position += 1) {
        if (token[0] == 'x') continue;

        try bus_ids.append(.{
            .id = try std.fmt.parseUnsigned(u32, token, 10),
            .position = position,
        });
    }

    var earliest_bus_id: u32 = 0;
    var earliest_departure: u32 = std.math.maxInt(u32);

    for (bus_ids.items) |bus_id| {
        const id = bus_id.id;
        var next_departure = id * (timestamp / id);
        if (next_departure < timestamp)
            next_departure += id;

        if (next_departure < earliest_departure) {
            earliest_departure = next_departure;
            earliest_bus_id = id;
        }
    }

    std.debug.print("Part 1: {}\n", .{
        earliest_bus_id * (earliest_departure - timestamp),
    });

    // Solve this problem for the first bus and buses of two highest ids.
    // In this way we get a much bigger value that we can use to increment
    // the counter. Luckily, it turned out to be big enough to get an answer
    // in a reasonable time.
    //
    // There's probably a better and cleaner way to solve this task but
    // for now I'm glad I found the answer on my own.
    const first = findTimestampFor2Buses(bus_ids.items, 521, 523, 0);
    const second = findTimestampFor2Buses(bus_ids.items, 521, 523, first);
    const diff_for_biggest_ids = second - first;

    var cur_timestamp: u64 = first;

    outer: while (true) : (cur_timestamp += diff_for_biggest_ids) {
        for (bus_ids.items[1..]) |bus_id| {
            if (@mod(cur_timestamp + bus_id.position, bus_id.id) != 0)
                continue :outer;
        }

        break;
    }

    std.debug.print("Part 2: {}\n", .{cur_timestamp});
}

// This function solves the problem for a smaller subset.
// It finds a timestamp such that the following buses satisfy
// the given condition: bus_ids[0].id, id1, id2.
// NOTE: It assumes that id1 < id2.
fn findTimestampFor2Buses(bus_ids: []const BusID, id1: u64, id2: u64, last_timestamp: u64) u64 {
    var bus_1_pos = for (bus_ids) |bus_id| {
        if (bus_id.id == id1) break bus_id.position;
    } else unreachable;

    var bus_2_pos = for (bus_ids) |bus_id| {
        if (bus_id.id == id2) break bus_id.position;
    } else unreachable;

    var diff: u64 = if (bus_2_pos > bus_1_pos)
        bus_2_pos - bus_1_pos
    else
        bus_1_pos - bus_2_pos;

    var t1: u64 = if (last_timestamp == 0) 0 else last_timestamp + bus_1_pos;
    var t2: u64 = if (last_timestamp == 0) 0 else last_timestamp + bus_2_pos;

    while (true) {
        t2 += id2;
        while ((t2 - t1) > id1) t1 += id1;

        if ((t2 - t1) == diff and @mod(t1 - bus_1_pos, bus_ids[0].id) == 0) {
            return (t1 - bus_1_pos);
        }
    }
}
