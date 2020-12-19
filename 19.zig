const std = @import("std");
const my_input = @embedFile("input/19");

const String = std.ArrayList(u8);

const Rule = struct {
    id: u32,
    char: ?u8,
    refs: [2]?u32,
    additional_refs: [2]?u32,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var rules = std.ArrayList(Rule).init(allocator);
    defer rules.deinit();

    var line_iter = std.mem.split(my_input, "\n");

    while (line_iter.next()) |line| {
        if (line.len == 0) break;

        var rule = Rule{
            .id = 0,
            .char = null,
            .refs = [_]?u32{ null, null },
            .additional_refs = [_]?u32{ null, null },
        };
        var token_iter = std.mem.tokenize(line, ": ");

        rule.id = try std.fmt.parseUnsigned(u32, token_iter.next().?, 10);

        var fill_additional_refs = false;
        var i: usize = 0;

        while (token_iter.next()) |token| {
            if (token[0] == '"') {
                rule.char = token[1];
                break;
            }
            if (token[0] == '|') {
                fill_additional_refs = true;
                i = 0;
                continue;
            }

            if (fill_additional_refs) {
                rule.additional_refs[i] = try std.fmt.parseUnsigned(u32, token, 10);
            } else {
                rule.refs[i] = try std.fmt.parseUnsigned(u32, token, 10);
            }

            i += 1;
        }

        try rules.append(rule);
    }

    std.sort.sort(Rule, rules.items, {}, (struct {
        fn cmp(context: void, a: Rule, b: Rule) bool {
            return a.id < b.id;
        }
    }).cmp);

    var messages = std.ArrayList([]const u8).init(allocator);
    defer messages.deinit();

    while (line_iter.next()) |line| {
        if (line.len == 0) break;
        try messages.append(line);
    }

    var result = try resolveRule(allocator, rules.items[0], rules.items);
    var valid_strings = result.items;

    var valid: u32 = 0;

    for (messages.items) |message| {
        if (message.len != valid_strings[0].items.len) continue;

        for (valid_strings) |valid_string| {
            if (std.mem.eql(u8, message, valid_string.items)) {
                valid += 1;
            }
        }
    }

    std.debug.print("Part 1: {}\n", .{valid});
}

// This is a memory leak fest for now
// I'm not really proud of it but it works ¯\_(ツ)_/¯
fn resolveRule(
    allocator: *std.mem.Allocator,
    rule: Rule,
    rules: []const Rule,
) anyerror!std.ArrayList(String) {
    if (rule.char) |char| {
        var strings = std.ArrayList(String).init(allocator);
        var string = String.init(allocator);
        try string.append(char);
        try strings.append(string);
        return strings;
    }
    // else we have references to other rules

    var strings1: std.ArrayList(String) = blk: {
        if (rule.refs[0]) |ref1| {
            var strings = try resolveRule(allocator, rules[ref1], rules);

            if (rule.refs[1]) |ref2| {
                var more_strings = try resolveRule(allocator, rules[ref2], rules);
                break :blk try mergeAndAppendStrings(
                    allocator,
                    strings.items,
                    more_strings.items,
                );
            }

            break :blk strings;
        }

        unreachable;
    };

    var strings2_opt: ?std.ArrayList(String) = blk: {
        if (rule.additional_refs[0]) |ref1| {
            var strings = try resolveRule(allocator, rules[ref1], rules);

            if (rule.additional_refs[1]) |ref2| {
                var more_strings = try resolveRule(allocator, rules[ref2], rules);
                break :blk try mergeAndAppendStrings(
                    allocator,
                    strings.items,
                    more_strings.items,
                );
            }

            break :blk strings;
        }

        break :blk null;
    };

    if (strings2_opt) |strings2| {
        return try mergeStrings(
            allocator,
            strings1.items,
            strings2.items,
        );
    } else {
        return strings1;
    }
}

fn mergeStrings(
    allocator: *std.mem.Allocator,
    strings1: []const String,
    strings2: []const String,
) !std.ArrayList(String) {
    var merged_strings = std.ArrayList(String).init(allocator);

    for (strings1) |string| {
        try merged_strings.append(string);
    }

    for (strings2) |string| {
        try merged_strings.append(string);
    }

    return merged_strings;
}

fn mergeAndAppendStrings(
    allocator: *std.mem.Allocator,
    strings1: []const String,
    strings2: []const String,
) !std.ArrayList(String) {
    var merged_strings = std.ArrayList(String).init(allocator);

    for (strings1) |string1| {
        for (strings2) |string2| {
            var string = String.init(allocator);
            try string.appendSlice(string1.items);
            try string.appendSlice(string2.items);
            try merged_strings.append(string);
        }
    }

    return merged_strings;
}
