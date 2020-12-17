const std = @import("std");
const my_input = @embedFile("input/16");

const NUM_OF_FIELDS = 20;

const Range = struct {
    start: u32 = 0,
    end: u32 = 0,
};

const Field = struct {
    ranges: [2]Range = [_]Range{ Range{}, Range{} },

    fn canBeInThisField(self: Field, value: usize) bool {
        return (value >= self.ranges[0].start and value <= self.ranges[0].end) or
            (value >= self.ranges[1].start and value <= self.ranges[1].end);
    }
};

const Ticket = struct {
    values: [NUM_OF_FIELDS]u32 = [_]u32{0} ** NUM_OF_FIELDS,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    //////////////
    //  PART 1  //
    //////////////

    var valid_numbers = [_]bool{false} ** 1000;
    var fields = [_]Field{.{}} ** NUM_OF_FIELDS;

    var line_iter = std.mem.tokenize(my_input, "\n");

    var i: usize = 0;
    while (i < NUM_OF_FIELDS) : (i += 1) {
        const line = line_iter.next().?;
        fields[i] = try parseField(line, &valid_numbers);
    }

    _ = line_iter.next().?; // your ticket:

    const my_ticket = try parseTicket(line_iter.next().?);

    _ = line_iter.next().?; // nearby tickets:

    var valid_tickets = std.ArrayList(Ticket).init(allocator);
    defer valid_tickets.deinit();

    var error_rate: u32 = 0;
    var invalid = false;
    while (line_iter.next()) |line| {
        const ticket = try parseTicket(line);
        invalid = false;

        for (ticket.values) |value| {
            if (!valid_numbers[value]) {
                error_rate += value;
                invalid = true;
            }
        }

        if (!invalid) {
            try valid_tickets.append(ticket);
        }
    }

    std.debug.print("Part 1: {}\n", .{error_rate});

    //////////////
    //  PART 2  //
    //////////////

    var available_field_indices = [_]bool{true} ** NUM_OF_FIELDS;

    // Find what fields are available for each field in the ticket.
    // Print it out to the console.
    var ticket_field_index: usize = 0;
    while (ticket_field_index < NUM_OF_FIELDS) : (ticket_field_index += 1) {
        std.mem.set(bool, &available_field_indices, true);

        for (valid_tickets.items) |ticket| {
            const value = ticket.values[ticket_field_index];

            var field_index: usize = 0;
            while (field_index < NUM_OF_FIELDS) : (field_index += 1) {
                if (!fields[field_index].canBeInThisField(value)) {
                    available_field_indices[field_index] = false;
                }
            }
        }

        for (available_field_indices) |available| {
            const char: u8 = if (available) 'X' else '.';
            std.debug.print("{c} ", .{char});
        }
        std.debug.print("\n", .{});
    }

    // The above loop produces the following output:
    //
    // . . . . . . . X . . . . . . . . . . . X
    // . . . . . X . X . . . . X X X . X . . X
    // X . X X . X . X . . . . X X X . X . . X
    // . . . . . . . X . . . . X X X . X . . X
    // X X X X X X . X . X X . X X X X X . X X
    // X . . X . X . X . . . . X X X . X . . X
    // . . . . . . . X . . . . . . . . . . . .
    // X X X X X X . X . . . . X X X X X . X X
    // . . . . . . . X . . . . X X X . . . . X
    // X X X X X X . X . . . . X X X . X . X X
    // . . . . . . . X . . . . . X X . . . . X
    // X X X X X X X X X X X X X X X X X X X X
    // . . . . . . . X . . . . . . X . . . . X
    // X . . . . X . X . . . . X X X . X . . X
    // X X X X X X . X . . X . X X X X X . X X
    // X . X X X X . X . . . . X X X . X . . X
    // X X X X X X X X X X X X X X X X X . X X
    // X X X X X X . X X X X X X X X X X . X X
    // X X X X X X . X . X X X X X X X X . X X
    // X X X X X X . X . . . . X X X . X . . X
    //
    // where rows represent ticket fields and columns
    // reprent fields from the rules section of input.
    // X means that a certain ticket field can be a
    // certain field from the rules section.
    //
    // The result matrix is small so I decided to
    // solve it by hand (I like this kind of puzzles).
    // The algorithm I used is as follows:
    //
    // Scan this matrix row by row until you find
    // a row with only one X in it. This means that
    // a certain ticket field (row) can hold only one
    // type of field (column). Once you find it,
    // remove other X's in this column. Repeat until
    // there's only one X left in every row.
    //
    // After solving it, I got the following output:
    //
    //    0 1 2 3 4 5
    //  0 . . . . . . . . . . . . . . . . . . . X
    //  1 . . . . . X . . . . . . . . . . . . . .
    //  2 . . X . . . . . . . . . . . . . . . . .
    //  3 . . . . . . . . . . . . . . . . X . . .
    //  4 . . . . . . . . . X . . . . . . . . . .
    //  5 . . . X . . . . . . . . . . . . . . . .
    //  6 . . . . . . . X . . . . . . . . . . . .
    //  7 . . . . . . . . . . . . . . . X . . . .
    //  8 . . . . . . . . . . . . X . . . . . . .
    //  9 . . . . . . . . . . . . . . . . . . X .
    // 10 . . . . . . . . . . . . . X . . . . . .
    // 11 . . . . . . X . . . . . . . . . . X . .
    // 12 . . . . . . . . . . . . . . X . . . . .
    // 13 X . . . . . . . . . . . . . . . . . . .
    // 14 . . . . . . . . . . X . . . . . . . . .
    // 15 . . . . X . . . . . . . . . . . . . . .
    // 16 . . . . . . X . . . . . . . . . . . . .
    // 17 . . . . . . . . X . . . . . . . . . . .
    // 18 . . . . . . . . . . . X . . . . . . . .
    // 19 . X . . . . . . . . . . . . . . . . . .
    //
    // We only care about departure fields so I only
    // marked columns 0-5.
    //
    // This means that:
    // - departure location (0) has index 13 in a ticket,
    // - departure station (1) has index 19 in a ticket,
    // - departure platform (2) has index 2 in a ticket,
    // - departure track (3) has index 5 in a ticket,
    // - departure date (4) has index 15 in a ticket,
    // - departure time (5) has index 1 in a ticket,

    var part2: u64 = 1;
    part2 *= my_ticket.values[13];
    part2 *= my_ticket.values[19];
    part2 *= my_ticket.values[2];
    part2 *= my_ticket.values[5];
    part2 *= my_ticket.values[15];
    part2 *= my_ticket.values[1];

    std.debug.print("Part 2: {}\n", .{part2});
}

fn parseField(line: []const u8, valid_numbers: *[1000]bool) !Field {
    const pos = std.mem.indexOfScalar(u8, line, ':').?;
    var token_iter = std.mem.tokenize(line[pos..], ": -");
    var field = Field{};

    var j: usize = 0;
    while (j < 2) : (j += 1) {
        const range_start = try std.fmt.parseUnsigned(u32, token_iter.next().?, 10);
        const range_end = try std.fmt.parseUnsigned(u32, token_iter.next().?, 10);

        field.ranges[j].start = range_start;
        field.ranges[j].end = range_end;

        var number: usize = range_start;
        while (number <= range_end) : (number += 1) {
            valid_numbers[number] = true;
        }

        _ = token_iter.next();
    }

    return field;
}

fn parseTicket(line: []const u8) !Ticket {
    var token_iter = std.mem.tokenize(line, ",");
    var ticket: Ticket = .{};

    var i: usize = 0;
    while (token_iter.next()) |token| : (i += 1) {
        const number = try std.fmt.parseUnsigned(u32, token, 10);
        ticket.values[i] = number;
    }

    return ticket;
}
