const std = @import("std");
const my_input = @embedFile("input/7");
const expectEqual = std.testing.expectEqual;

const Bag = struct {
    color: []const u8,
    contains: []const ColorWithCount,
};

const ColorWithCount = struct {
    color: []const u8,
    count: u32,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var color_to_bag_map = try parseInput(allocator, my_input);

    var bags_iter = color_to_bag_map.iterator();
    var part1: u32 = 0;

    while (bags_iter.next()) |entry| {
        const bag = entry.value;

        if (canContainShinyGold(bag, color_to_bag_map)) {
            part1 += 1;
        }
    }

    part1 -= 1; // shiny gold bags can't contain themselves!

    std.debug.print("Part 1: {}\n", .{part1});

    var part2 = findTotalNumOfBags(
        color_to_bag_map.get("shiny gold").?,
        color_to_bag_map,
    );

    std.debug.print("Part 2: {}\n", .{part2});
}

fn canContainShinyGold(bag: Bag, map: std.StringHashMap(Bag)) bool {
    if (std.mem.eql(u8, bag.color, "shiny gold")) return true;

    for (bag.contains) |other_bag| {
        if (canContainShinyGold(map.get(other_bag.color).?, map)) {
            return true;
        }
    }

    return false;
}

fn findTotalNumOfBags(bag: Bag, map: std.StringHashMap(Bag)) u32 {
    var total_num_of_bags: u32 = 0;

    for (bag.contains) |other_bag| {
        total_num_of_bags += other_bag.count;
        total_num_of_bags += other_bag.count * findTotalNumOfBags(
            map.get(other_bag.color).?,
            map,
        );
    }

    return total_num_of_bags;
}

fn parseInput(allocator: *std.mem.Allocator, input: []const u8) !std.StringHashMap(Bag) {
    var color_to_bag_map = std.StringHashMap(Bag).init(allocator);
    var contains = std.ArrayList(ColorWithCount).init(allocator);
    var line_iter = std.mem.tokenize(input, "\n");

    while (line_iter.next()) |line| {
        var cur_pos: usize = 0;

        cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;
        cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;

        const color = line[0..cur_pos];

        cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;
        cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;

        var count_end_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;

        if (!std.mem.eql(u8, line[cur_pos + 1 .. count_end_pos], "no")) {
            while (true) {
                var prev_pos = cur_pos;
                cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;

                const count_str = line[prev_pos + 1 .. cur_pos];
                const count = try std.fmt.parseUnsigned(u32, count_str, 10);

                prev_pos = cur_pos;
                cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;
                cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ').?;

                const contains_color = line[prev_pos + 1 .. cur_pos];
                try contains.append(.{
                    .color = contains_color,
                    .count = count,
                });

                cur_pos = std.mem.indexOfScalarPos(u8, line, cur_pos + 1, ' ') orelse {
                    break;
                };
            }
        }

        const result = try color_to_bag_map.getOrPut(color);
        result.entry.*.value = Bag{
            .color = color,
            .contains = contains.toOwnedSlice(),
        };
    }

    return color_to_bag_map;
}
