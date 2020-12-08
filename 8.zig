const std = @import("std");
const my_input = @embedFile("input/8");

const Op = enum {
    jmp, nop, acc
};

const Instruction = struct {
    op: Op,
    arg: i32,
};

const Processor = struct {
    instructions: []Instruction,
    executions: []u32 = undefined,
    ins_pointer: usize = 0,
    acc: i32 = 0,
    loop_detected: bool = false,

    pub fn init(allocator: anytype, instructions: []Instruction) !Processor {
        return Processor{
            .executions = try allocator.alloc(u32, instructions.len),
            .instructions = instructions,
        };
    }

    fn run(self: *Processor) void {
        std.mem.set(u32, self.executions, 0);

        self.ins_pointer = 0;
        self.acc = 0;

        while (self.validatePointer()) : (self.ins_pointer += 1) {
            self.executions[self.ins_pointer] += 1;
            var cur_ins = &self.instructions[self.ins_pointer];

            switch (cur_ins.op) {
                .jmp => self.ins_pointer = @intCast(
                    usize,
                    @intCast(i32, self.ins_pointer) + cur_ins.arg - 1,
                ),
                .acc => self.acc += cur_ins.arg,
                else => {},
            }
        }

        self.loop_detected = self.ins_pointer < self.instructions.len;
    }

    fn validatePointer(self: Processor) bool {
        return self.ins_pointer < self.instructions.len and
            self.executions[self.ins_pointer] < 1;
    }
};

fn parseInstructions(allocator: *std.mem.Allocator) ![]Instruction {
    var instructions = std.ArrayList(Instruction).init(allocator);

    var line_iter = std.mem.tokenize(my_input, "\n");

    while (line_iter.next()) |line| {
        var token_iter = std.mem.tokenize(line, " ");
        var op_str = token_iter.next().?;
        var op = Op.nop;

        if (std.mem.eql(u8, op_str, "jmp")) op = Op.jmp;
        if (std.mem.eql(u8, op_str, "acc")) op = Op.acc;

        try instructions.append(.{
            .op = op,
            .arg = try std.fmt.parseInt(i32, token_iter.next().?, 10),
        });
    }

    return instructions.toOwnedSlice();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var instructions = try parseInstructions(allocator);
    var processor = try Processor.init(allocator, instructions);

    processor.run();

    std.debug.print("Part 1: {}\n", .{processor.acc});

    for (processor.instructions) |*ins| {
        var op_tmp = ins.op;

        switch (ins.op) {
            .jmp => ins.op = Op.nop,
            .nop => ins.op = Op.jmp,
            else => {},
        }

        processor.run();

        if (!processor.loop_detected) break;

        ins.op = op_tmp;
    }

    std.debug.print("Part 2: {}\n", .{processor.acc});
}
