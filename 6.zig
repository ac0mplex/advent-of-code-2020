const std = @import("std");
const my_input = @embedFile("input/6");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    std.debug.print("Part 1: {}\n", .{part1(my_input)});
    std.debug.print("Part 2: {}\n", .{part2(my_input)});
}

fn part1(input: []const u8) u32 {
    var line_iter = std.mem.split(input, "\n");

    var finished: bool = false;
    var yes_answers: u32 = 0;

    while (!finished) {
        yes_answers += findYesAnswersForGroup(&line_iter, &finished);
    }

    return yes_answers;
}

fn findYesAnswersForGroup(iter: *std.mem.SplitIterator, finished: *bool) u32 {
    var yes_answers: u32 = 0;
    var answers = [_]bool{false} ** (('z' - 'a') + 1);

    while (iter.next()) |line| {
        if (line.len == 0) return yes_answers;

        for (line) |char| {
            var index: usize = char - 'a';

            if (!answers[index]) {
                answers[index] = true;
                yes_answers += 1;
            }
        }
    }

    finished.* = true;
    return yes_answers;
}

fn part2(input: []const u8) u32 {
    var line_iter = std.mem.split(input, "\n");

    var finished: bool = false;
    var yes_answers: u32 = 0;

    while (!finished) {
        yes_answers += findYesAnswersForGroup2(&line_iter, &finished);
    }

    return yes_answers;
}

fn findYesAnswersForGroup2(iter: *std.mem.SplitIterator, finished: *bool) u32 {
    var answers = [_]u32{0} ** (('z' - 'a') + 1);
    var num_of_people_in_group: u32 = 0;

    while (iter.next()) |line| {
        if (line.len == 0) break;

        num_of_people_in_group += 1;

        for (line) |char| {
            var index: usize = char - 'a';
            answers[index] += 1;
        }
    } else {
        finished.* = true;
    }

    if (num_of_people_in_group == 0) return 0;

    var yes_answers: u32 = 0;
    for (answers) |num_of_answers| {
        yes_answers += @boolToInt(num_of_answers == num_of_people_in_group);
    }

    return yes_answers;
}

const sample_input =
    \\abc
    \\
    \\a
    \\b
    \\c
    \\
    \\ab
    \\ac
    \\
    \\a
    \\a
    \\a
    \\a
    \\
    \\b
;

// I hope I won't need those casts in the future
// https://github.com/ziglang/zig/issues/4437
test "part_1_sample_input" {
    expectEqual(@as(u32, 3), part1("abc"));
    expectEqual(@as(u32, 3), part1("a\nb\nc"));
    expectEqual(@as(u32, 3), part1("ab\nac"));
    expectEqual(@as(u32, 1), part1("a\na\na\na"));
    expectEqual(@as(u32, 1), part1("b"));

    expectEqual(@as(u32, 11), part1(sample_input));
}

test "part_2_sample_input" {
    expectEqual(@as(u32, 3), part2("abc"));
    expectEqual(@as(u32, 0), part2("a\nb\nc"));
    expectEqual(@as(u32, 1), part2("ab\nac"));
    expectEqual(@as(u32, 1), part2("a\na\na\na"));
    expectEqual(@as(u32, 1), part2("b"));

    expectEqual(@as(u32, 6), part2(sample_input));
}
