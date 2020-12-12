const std = @import("std");
const expectEqual = std.testing.expectEqual;

const my_input = @embedFile("input/12");

const Instruction = struct {
    action: u8,
    value: i32,
};

const Pos = struct {
    x: i32,
    y: i32,
};

const Dir = enum {
    S,
    W,
    N,
    E,

    fn rotate(self: Dir, degrees: i32) Dir {
        const delta = @divExact(degrees, 90);
        const self_int = @intCast(i32, @enumToInt(self));
        const new_dir_int = @mod(self_int + delta, 4);

        return @intToEnum(Dir, @intCast(u2, new_dir_int));
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const instructions = blk: {
        var array_list = std.ArrayList(Instruction).init(allocator);
        var line_iter = std.mem.tokenize(my_input, "\n");

        while (line_iter.next()) |line| {
            try array_list.append(.{
                .action = line[0],
                .value = try std.fmt.parseInt(i32, line[1..], 10),
            });
        }

        break :blk array_list.toOwnedSlice();
    };

    const part1 = part1: {
        var pos = Pos{ .x = 0, .y = 0 };
        var dir = Dir.E;

        for (instructions) |instruction| {
            switch (instruction.action) {
                'S' => pos.y -= instruction.value,
                'W' => pos.x -= instruction.value,
                'N' => pos.y += instruction.value,
                'E' => pos.x += instruction.value,
                'F' => switch (dir) {
                    .S => pos.y -= instruction.value,
                    .W => pos.x -= instruction.value,
                    .N => pos.y += instruction.value,
                    .E => pos.x += instruction.value,
                },
                'L' => dir = dir.rotate(-instruction.value),
                'R' => dir = dir.rotate(instruction.value),
                else => unreachable,
            }
        }

        break :part1 (try std.math.absInt(pos.x)) + (try std.math.absInt(pos.y));
    };

    std.debug.print("Part 1: {}\n", .{part1});

    const part2 = part2: {
        var pos = Pos{ .x = 0, .y = 0 };
        var waypoint = Pos{ .x = 10, .y = 1 };

        for (instructions) |instruction| {
            switch (instruction.action) {
                'S' => waypoint.y -= instruction.value,
                'W' => waypoint.x -= instruction.value,
                'N' => waypoint.y += instruction.value,
                'E' => waypoint.x += instruction.value,
                'F' => {
                    pos.x += instruction.value * waypoint.x;
                    pos.y += instruction.value * waypoint.y;
                },
                'L' => rotate(&waypoint, -instruction.value),
                'R' => rotate(&waypoint, instruction.value),
                else => unreachable,
            }
        }

        break :part2 (try std.math.absInt(pos.x)) + (try std.math.absInt(pos.y));
    };

    std.debug.print("Part 2: {}\n", .{part2});
}

fn rotate(waypoint: *Pos, degrees: i32) void {
    var delta = @mod(degrees, 360);

    switch (delta) {
        90 => {
            const tmp = waypoint.y;
            waypoint.y = -waypoint.x;
            waypoint.x = tmp;
        },
        180 => {
            waypoint.x *= -1;
            waypoint.y *= -1;
        },
        270 => {
            const tmp = waypoint.y;
            waypoint.y = waypoint.x;
            waypoint.x = -tmp;
        },
        else => unreachable,
    }
}

test "rotate" {
    expectEqual(Dir.rotate(Dir.S, 90), Dir.W);
    expectEqual(Dir.rotate(Dir.S, 180), Dir.N);
    expectEqual(Dir.rotate(Dir.S, 270), Dir.E);
    expectEqual(Dir.rotate(Dir.S, 360), Dir.S);
    expectEqual(Dir.rotate(Dir.S, 450), Dir.W);

    expectEqual(Dir.rotate(Dir.S, -90), Dir.E);
    expectEqual(Dir.rotate(Dir.S, -180), Dir.N);
    expectEqual(Dir.rotate(Dir.S, -270), Dir.W);
    expectEqual(Dir.rotate(Dir.S, -360), Dir.S);
    expectEqual(Dir.rotate(Dir.S, -450), Dir.E);
}
