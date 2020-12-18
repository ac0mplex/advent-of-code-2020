const std = @import("std");
const my_input = @embedFile("input/18");

const Operator = enum {
    add, multiply
};

const Atom = union(enum) {
    number: u64,
    operator: Operator,
    open_paranthesis: void,
    close_paranthesis: void,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var expression = std.ArrayList(Atom).init(allocator);
    var line_iter = std.mem.tokenize(my_input, "\n");

    var part1: u64 = 0;
    var part2: u64 = 0;

    while (line_iter.next()) |line| {
        expression.shrinkRetainingCapacity(0);

        for (line) |char| {
            const atom: Atom = switch (char) {
                ' ' => continue,
                '*' => Atom{ .operator = .multiply },
                '+' => Atom{ .operator = .add },
                '(' => Atom.open_paranthesis,
                ')' => Atom.close_paranthesis,
                else => Atom{ .number = char - '0' },
            };

            try expression.append(atom);
        }

        part1 += eval(expression.items, 0).result;

        try eval2(&expression, 0);
        part2 += expression.items[0].number;
    }

    std.debug.print("Part 1: {}\n", .{part1});
    std.debug.print("Part 2: {}\n", .{part2});
}

const EvalResult = struct {
    result: u64,
    last_pos: usize,
};

fn eval(expression: []const Atom, start: usize) EvalResult {
    var accumulator: u64 = 0;
    var pos: usize = start;
    var last_number: u64 = 0;
    var last_operator: Operator = .add;

    while (pos < expression.len) : (pos += 1) {
        const atom = expression[pos];

        switch (atom) {
            .number => |number| {
                last_number = number;
            },
            .operator => |operator| {
                switch (last_operator) {
                    .add => accumulator += last_number,
                    .multiply => accumulator *= last_number,
                }
                last_operator = operator;
            },
            .open_paranthesis => {
                const result = eval(expression, pos + 1);
                last_number = result.result;
                pos = result.last_pos;
            },
            .close_paranthesis => {
                break;
            },
        }
    }

    switch (last_operator) {
        .add => accumulator += last_number,
        .multiply => accumulator *= last_number,
    }

    return .{ .result = accumulator, .last_pos = pos };
}

fn eval2(expression: *std.ArrayList(Atom), start: usize) anyerror!void {
    // Get rid of parantheses first
    var pos = start;
    while (pos < expression.items.len) {
        const atom = expression.items[pos];

        switch (atom) {
            .open_paranthesis => {
                try eval2(expression, pos + 1);
                _ = expression.orderedRemove(pos);
                continue;
            },
            .close_paranthesis => {
                _ = expression.orderedRemove(pos);
                break;
            },
            else => pos += 1,
        }
    }

    // Eval remaining operators
    var end = pos;
    end = try evalAllOperatorsInRange(expression, Operator.add, start, end);
    end = try evalAllOperatorsInRange(expression, Operator.multiply, start, end);
}

fn evalAllOperatorsInRange(
    expression: *std.ArrayList(Atom),
    operator: Operator,
    start: usize,
    end: usize,
) !usize {
    var cur_end = end;

    while (true) {
        // Find position of the operator
        var op_pos = start;
        while (op_pos < cur_end) : (op_pos += 1) {
            switch (expression.items[op_pos]) {
                .operator => |cur_operator| {
                    if (cur_operator == operator) break;
                },
                else => {},
            }
        } else break;

        const num1 = expression.items[op_pos - 1].number;
        const num2 = expression.items[op_pos + 1].number;

        try expression.replaceRange(
            op_pos - 1,
            3,
            &[_]Atom{Atom{
                .number = switch (operator) {
                    .add => num1 + num2,
                    .multiply => num1 * num2,
                },
            }},
        );

        cur_end -= 2;
    }

    return cur_end;
}
