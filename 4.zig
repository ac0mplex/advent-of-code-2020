const std = @import("std");
const input = @embedFile("input/4");

const HeightUnit = enum {
    in, cm, unknown
};

// zig fmt: off
const Passport = struct {
    birthYear: ?u32 = null,
    issueYear: ?u32 = null,
    expirationYear: ?u32 = null,
    height: ?u32 = null,
    heightUnit: ?HeightUnit = null,
    hairColor: ?[]const u8 = null,
    eyeColor: ?[]const u8 = null,
    pid: ?[]const u8 = null,

    pub fn setField(self: *Passport, field_name: []const u8, field_value: []const u8) void {
        if (std.mem.eql(u8, field_name, "byr")) {
            self.birthYear = std.fmt.parseUnsigned(u32, field_value, 10) catch 0;

        } else if (std.mem.eql(u8, field_name, "iyr")) {
            self.issueYear = std.fmt.parseUnsigned(u32, field_value, 10) catch 0;

        } else if (std.mem.eql(u8, field_name, "eyr")) {
            self.expirationYear = std.fmt.parseUnsigned(u32, field_value, 10) catch 0;

        } else if (std.mem.eql(u8, field_name, "hgt")) {

            if (std.mem.indexOf(u8, field_value, "cm")) |pos| {
                self.height = std.fmt.parseUnsigned(u32, field_value[0..pos], 10) catch 0;
                self.heightUnit = HeightUnit.cm;
            } else if (std.mem.indexOf(u8, field_value, "in")) |pos| {
                self.height = std.fmt.parseUnsigned(u32, field_value[0..pos], 10) catch 0;
                self.heightUnit = HeightUnit.in;
            } else {
                self.height = 0;
                self.heightUnit = HeightUnit.unknown;
            }

        } else if (std.mem.eql(u8, field_name, "hcl")) {
            self.hairColor = field_value;

        } else if (std.mem.eql(u8, field_name, "ecl")) {
            self.eyeColor = field_value;

        } else if (std.mem.eql(u8, field_name, "pid")) {
            self.pid = field_value;

        }
    }

    pub fn isValid1(self: Passport) bool {
        return
            self.birthYear != null and
            self.issueYear != null and
            self.expirationYear != null and
            self.height != null and
            self.heightUnit != null and
            self.hairColor != null and
            self.eyeColor != null and
            self.pid != null;
    }

    pub fn isValid2(self: Passport) bool {
        return
            self.isBirthYearValid2() and
            self.isIssueYearValid2() and
            self.isExpirationYearValid2() and
            self.isHeightValid2() and
            self.isHairColorValid2() and
            self.isEyeColorValid2() and
            self.isPIDValid2();
    }

    fn isBirthYearValid2(self: Passport) bool {
        const birthYear = self.birthYear orelse return false;
        return birthYear >= 1920 and birthYear <= 2002;
    }

    fn isIssueYearValid2(self: Passport) bool {
        const issueYear = self.issueYear orelse return false;
        return issueYear >= 2010 and issueYear <= 2020;
    }

    fn isExpirationYearValid2(self: Passport) bool {
        const expirationYear = self.expirationYear orelse return false;
        return expirationYear >= 2020 and expirationYear <= 2030;
    }

    fn isHeightValid2(self: Passport) bool {
        const heightUnit = self.heightUnit orelse return false;
        const height = self.height orelse return false;

        return switch (heightUnit) {
            HeightUnit.cm => height >= 150 and height <= 193,
            HeightUnit.in => height >= 59 and height <= 76,
            else => false,
        };
    }

    fn isHairColorValid2(self: Passport) bool {
        const hairColor = self.hairColor orelse return false;

        if (hairColor.len != 7) return false;
        if (hairColor[0] != '#') return false;

        for (hairColor[1..]) |char| {
            if (!std.ascii.isDigit(char) and !(char >= 'a' and char <= 'f')) {
                return false;
            }
        }

        return true;
    }

    fn isEyeColorValid2(self: Passport) bool {
        const eyeColor = self.eyeColor orelse return false;

        const valid_colors = [_][]const u8{
            "amb", "blu", "brn", "gry", "grn", "hzl", "oth",
        };

        for (valid_colors) |color| {
            if (std.mem.eql(u8, eyeColor, color)) {
                return true;
            }
        }

        return false;
    }

    fn isPIDValid2(self: Passport) bool {
        const pid = self.pid orelse return false;

        if (pid.len != 9) return false;

        for (pid) |char| {
            if (!std.ascii.isDigit(char)) {
                return false;
            }
        }

        return true;
    }
};
// zig fmt: on

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var line_iter = std.mem.split(input, "\n");

    var finished = false;
    var passports = std.ArrayList(Passport).init(allocator);

    while (!finished) {
        try passports.append(readPassport(&line_iter, &finished));
    }

    var valid1: u32 = 0;
    var valid2: u32 = 0;
    for (passports.items) |passport| {
        valid1 += @boolToInt(passport.isValid1());
        valid2 += @boolToInt(passport.isValid2());
    }

    std.debug.print("Part 1: {}\n", .{valid1});
    std.debug.print("Part 2: {}\n", .{valid2});
}

fn readPassport(line_iter: *std.mem.SplitIterator, finished: *bool) Passport {
    var passport: Passport = .{};

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var fields_iter = std.mem.tokenize(line, " :");

        while (true) {
            const field_name = fields_iter.next() orelse break;
            const field_value = fields_iter.next() orelse {
                std.debug.panic("Invalid input", .{});
            };

            passport.setField(field_name, field_value);
        }
    } else {
        finished.* = true;
        return passport;
    }

    return passport;
}
