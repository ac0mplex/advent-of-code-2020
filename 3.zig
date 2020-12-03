const std = @import("std");
const input = @embedFile("input/3");

const Trees = struct {
    data: []const u8,
    row_length: u32,

    pub fn init(data: []const u8) Trees {
        return Trees{
            .data = data,
            .row_length = @intCast(u32, std.mem.indexOf(u8, data, "\n").? + 1),
        };
    }

    pub fn findNumOfTreesOnSlope(self: Trees, dx: u32, dy: u32) u64 {
        var trees_on_the_way: u64 = 0;

        var x: u32 = dx;
        var y: u32 = dy;

        var i: usize = y * self.row_length + x;

        while (i < self.data.len) {
            trees_on_the_way += @boolToInt(self.data[i] == '#');

            x = (x + dx) % (self.row_length - 1);
            y += dy;

            i = y * self.row_length + x;
        }

        return trees_on_the_way;
    }
};

pub fn main() !void {
    const trees = Trees.init(input);

    const part1 = trees.findNumOfTreesOnSlope(3, 1);

    std.debug.print("{}\n", .{part1});

    const part2 = part1 *
        trees.findNumOfTreesOnSlope(1, 1) *
        trees.findNumOfTreesOnSlope(5, 1) *
        trees.findNumOfTreesOnSlope(7, 1) *
        trees.findNumOfTreesOnSlope(1, 2);

    std.debug.print("{}\n", .{part2});
}
