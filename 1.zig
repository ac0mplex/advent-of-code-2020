const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input/1", .{
        .read = true,
        .write = false,
    });
    defer file.close();

    var numbers = std.ArrayList(u32).init(&gpa.allocator);
    defer numbers.deinit();

    var buffer = std.ArrayList(u8).init(&gpa.allocator);
    defer buffer.deinit();

    const reader = file.reader();

    while (true) {
        reader.readUntilDelimiterArrayList(&buffer, '\n', std.math.maxInt(usize)) catch {
            break;
        };

        const number = try std.fmt.parseInt(u32, buffer.items, 10);
        try numbers.append(number);
    }

    std.debug.print("{}\n", .{solve(numbers.items)});
    std.debug.print("{}\n", .{solve2(numbers.items)});
}

pub fn solve(items: []u32) u32 {
    for (items) |item1| {
        for (items) |item2| {
            if (item1 + item2 == 2020) {
                return item1 * item2;
            }
        }
    }

    return 0;
}

pub fn solve2(items: []u32) u32 {
    for (items) |item1| {
        for (items) |item2| {
            for (items) |item3| {
                if (item1 + item2 + item3 == 2020) {
                    return item1 * item2 * item3;
                }
            }
        }
    }

    return 0;
}
