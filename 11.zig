const std = @import("std");
const my_input = @embedFile("input/11");

const Dir = struct { x: i64, y: i64 };

const dirs = [_]Dir{
    .{ .x = 1, .y = 0 },
    .{ .x = -1, .y = 0 },
    .{ .x = 0, .y = 1 },
    .{ .x = 0, .y = -1 },

    .{ .x = 1, .y = 1 },
    .{ .x = 1, .y = -1 },
    .{ .x = -1, .y = 1 },
    .{ .x = -1, .y = -1 },
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var tiles: [][]const u8 = blk: {
        var all_tiles_buffer = std.ArrayList([]const u8).init(allocator);
        var line_iter = std.mem.tokenize(my_input, "\n");

        while (line_iter.next()) |line| {
            try all_tiles_buffer.append(line);
        }

        break :blk all_tiles_buffer.toOwnedSlice();
    };

    var tiles_old = try dupe2D(allocator, u8, tiles);
    var tiles_new = try dupe2D(allocator, u8, tiles);

    const part1 = solve(tiles_old, tiles_new, checkIfOccupied1, 4);
    std.debug.print("Part 1: {}\n", .{part1});

    tiles_old = try dupe2D(allocator, u8, tiles);
    tiles_new = try dupe2D(allocator, u8, tiles);

    const part2 = solve(tiles_old, tiles_new, checkIfOccupied2, 5);
    std.debug.print("Part 2: {}\n", .{part2});
}

fn dupe2D(allocator: anytype, comptime T: type, source: []const []const T) ![][]T {
    var tmp = try allocator.alloc([]T, source.len);
    for (tmp) |*row, i| {
        row.* = try allocator.dupe(u8, source[i]);
    }
    return tmp;
}

fn checkIfOccupied1(tiles: [][]u8, pos_x: i64, pos_y: i64, dir_x: i64, dir_y: i64) bool {
    var x: i64 = pos_x + dir_x;
    var y: i64 = pos_y + dir_y;

    if (x >= 0 and x < tiles[0].len and
        y >= 0 and y < tiles.len)
    {
        return tiles[@intCast(usize, y)][@intCast(usize, x)] == '#';
    }

    return false;
}

fn checkIfOccupied2(tiles: [][]u8, pos_x: i64, pos_y: i64, dir_x: i64, dir_y: i64) bool {
    var x: i64 = pos_x + dir_x;
    var y: i64 = pos_y + dir_y;

    while (x >= 0 and x < tiles[0].len and y >= 0 and y < tiles.len) : ({
        x += dir_x;
        y += dir_y;
    }) {
        const tile = tiles[@intCast(usize, y)][@intCast(usize, x)];
        if (tile == '#') return true;
        if (tile == 'L') return false;
    }

    return false;
}

fn solve(tiles_old: [][]u8, tiles_new: [][]u8, checkIfOccupied: anytype, occupiedRule: u32) u32 {
    var changed = true;

    while (changed) {
        changed = false;

        for (tiles_old) |row_of_tiles, y| {
            for (row_of_tiles) |tile, x| {
                if (tile == '.') continue;

                var num_of_occupied: u32 = 0;

                for (dirs) |dir| {
                    num_of_occupied += @boolToInt(checkIfOccupied(
                        tiles_old,
                        @intCast(i64, x),
                        @intCast(i64, y),
                        dir.x,
                        dir.y,
                    ));
                }

                if (tile == 'L') {
                    if (num_of_occupied == 0) {
                        tiles_new[y][x] = '#';
                        changed = true;
                    }
                } else { // '#'
                    if (num_of_occupied >= occupiedRule) {
                        tiles_new[y][x] = 'L';
                        changed = true;
                    }
                }
            }
        }

        for (tiles_new) |row_of_tiles, i| {
            std.mem.copy(u8, tiles_old[i], row_of_tiles);
        }
    }

    var occupied_seats: u32 = 0;

    for (tiles_new) |row_of_tiles| {
        for (row_of_tiles) |tile| {
            occupied_seats += @boolToInt(tile == '#');
        }
    }

    return occupied_seats;
}
