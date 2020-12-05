const std = @import("std");
const input = @embedFile("input/5");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var line_iter = std.mem.tokenize(input, "\n");

    var ids = [_]bool{false} ** (1 << 10);
    var highest_id: u32 = 0;
    var lowest_id: u32 = std.math.maxInt(u32);

    while (line_iter.next()) |line| {
        var seat_id: u32 = decodeSeatID2(line);
        ids[seat_id] = true;
        lowest_id = std.math.min(lowest_id, seat_id);
        highest_id = std.math.max(highest_id, seat_id);
    }

    std.debug.print("Highest seat ID: {}\n", .{highest_id});

    for (ids[lowest_id..]) |occupied, id| {
        if (!occupied) {
            std.debug.print("My seat: {}\n", .{id + lowest_id});
            break;
        }
    }
}

fn decodeSeatID(seat: []const u8) u32 {
    var row_start: u32 = 0;
    var row_end: u32 = 128;

    for (seat[0..7]) |char| {
        switch (char) {
            'F' => row_end -= (row_end - row_start) / 2,
            'B' => row_start += (row_end - row_start) / 2,
            else => std.debug.panic("Invalid input\n", .{}),
        }
    }

    var column_start: u32 = 0;
    var column_end: u32 = 8;

    for (seat[7..10]) |char| {
        switch (char) {
            'L' => column_end -= (column_end - column_start) / 2,
            'R' => column_start += (column_end - column_start) / 2,
            else => std.debug.panic("Invalid input\n", .{}),
        }
    }

    return row_start * 8 + column_start;
}

fn decodeSeatID2(seat: []const u8) u32 {
    var row: u32 = 0;

    for (seat[0..7]) |char, i| {
        if (char == 'B') row += @as(u32, 1) << @intCast(u5, 6 - i);
    }

    var column: u32 = 0;

    for (seat[7..10]) |char, i| {
        if (char == 'R') column += @as(u32, 1) << @intCast(u5, 2 - i);
    }

    return row * 8 + column;
}

test "part_1_sample_input" {
    expectEqual(@as(u32, 567), decodeSeatID("BFFFBBFRRR"));
    expectEqual(@as(u32, 119), decodeSeatID("FFFBBBFRRR"));
    expectEqual(@as(u32, 820), decodeSeatID("BBFFBBFRLL"));
}
