const std = @import("std");

const PasswordRule = struct {
    password: []const u8,
    requiredChar: u8,
    min: u32,
    max: u32,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const file_content = try std.fs.cwd().readFileAlloc(
        allocator,
        "input/2",
        std.math.maxInt(usize),
    );

    var passwordRules = try parsePasswords(allocator, file_content);

    std.debug.print("{}\n", .{validatePasswords1(passwordRules)});
    std.debug.print("{}\n", .{validatePasswords2(passwordRules)});
}

fn parsePasswords(allocator: *std.mem.Allocator, data: []u8) ![]PasswordRule {
    var passwordRules = std.ArrayList(PasswordRule).init(allocator);
    var lines = std.mem.tokenize(data, "\n");

    while (lines.next()) |line| {
        var tokens = std.mem.tokenize(line, " -:");

        const minStr = tokens.next() orelse std.debug.panic("Wrong format!", .{});
        const maxStr = tokens.next() orelse std.debug.panic("Wrong format!", .{});
        const requiredCharToken = tokens.next() orelse std.debug.panic("Wrong format!", .{});
        const password = tokens.next() orelse std.debug.panic("Wrong format!", .{});

        try passwordRules.append(.{
            .password = password,
            .requiredChar = requiredCharToken[0],
            .min = try std.fmt.parseUnsigned(u32, minStr, 10),
            .max = try std.fmt.parseUnsigned(u32, maxStr, 10),
        });
    }

    return passwordRules.toOwnedSlice();
}

fn validatePasswords1(passwordRules: []const PasswordRule) u32 {
    var validated: u32 = 0;

    for (passwordRules) |rule| {
        var numOfRequiredChar: u32 = 0;

        for (rule.password) |char| {
            if (char == rule.requiredChar) {
                numOfRequiredChar += 1;
            }
        }

        if (numOfRequiredChar >= rule.min and numOfRequiredChar <= rule.max) {
            validated += 1;
        }
    }

    return validated;
}

fn validatePasswords2(passwordRules: []const PasswordRule) u32 {
    var validated: u32 = 0;

    for (passwordRules) |rule| {
        var firstAppears = rule.password[rule.min - 1] == rule.requiredChar;
        var secondAppears = rule.password[rule.max - 1] == rule.requiredChar;

        if (firstAppears != secondAppears) {
            validated += 1;
        }
    }

    return validated;
}
