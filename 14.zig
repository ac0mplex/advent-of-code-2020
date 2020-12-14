const std = @import("std");
const my_input = @embedFile("input/14");

const Memory = struct {
    _map: std.AutoArrayHashMap(usize, *[36]u8),
    _allocator: *std.mem.Allocator,

    fn init(allocator: anytype) Memory {
        return .{
            ._map = std.AutoArrayHashMap(usize, *[36]u8).init(allocator),
            ._allocator = allocator,
        };
    }

    fn deinit(self: *Memory) void {
        var iter = self._map.iterator();
        while (iter.next()) |entry| {
            self._allocator.free(entry.value);
        }

        self._map.deinit();
    }

    fn getAt(self: Memory, index: usize) *const [36]u8 {
        return self._map.getEntry(index).?.value;
    }

    fn setAt(self: *Memory, index: usize, value: *const [36]u8) !void {
        const result = try self._map.getOrPut(index);
        const entry = result.entry;

        if (!result.found_existing) {
            entry.value = (try self._allocator.dupe(u8, value))[0..36];
        } else {
            std.mem.copy(u8, entry.value, value);
        }
    }

    fn setWithBitmaskAt1(self: *Memory, index: usize, value: *const [36]u8, bitmask: *const [36]u8) !void {
        var buffer: [36]u8 = undefined;

        for (bitmask) |bit, i| {
            if (bit == 'X') {
                buffer[i] = value[i];
            } else {
                buffer[i] = bit;
            }
        }

        try self.setAt(index, &buffer);
    }

    fn setWithBitmaskAt2(self: *Memory, index: usize, value: *const [36]u8, bitmask: *const [36]u8) !void {
        var address_buffer: [36]u8 = undefined;
        var floating_bits_buffer = [_]usize{0} ** 36;
        var floating_count: usize = 0;

        Memory.formatToMemoryLayout(&address_buffer, @intCast(u36, index));

        for (bitmask) |bit, i| {
            switch (bit) {
                '0' => {},
                '1' => address_buffer[i] = '1',
                'X' => {
                    address_buffer[i] = 'X';
                    floating_bits_buffer[floating_count] = i;
                    floating_count += 1;
                },
                else => unreachable,
            }
        }

        const num_of_combinations = std.math.pow(usize, 2, floating_count);

        var i: usize = 0;
        while (i < num_of_combinations) : (i += 1) {
            var j: usize = 0;
            while (j < floating_count) : (j += 1) {
                const cur_floating_index = floating_bits_buffer[j];

                const remainder = i % std.math.pow(usize, 2, floating_count - j);
                const divisor = std.math.pow(usize, 2, floating_count - (j + 1));
                const floating_bit = @intCast(u8, remainder / divisor);

                address_buffer[cur_floating_index] = '0' + floating_bit;
            }

            const address = std.fmt.parseUnsigned(usize, &address_buffer, 2) catch {
                std.debug.panic("whoopsie", .{});
            };

            try self.setAt(address, value);
        }
    }

    fn findSum(self: Memory) u64 {
        var sum: u64 = 0;
        var iter = self._map.iterator();

        while (iter.next()) |entry| {
            sum += std.fmt.parseUnsigned(u36, entry.value, 2) catch {
                std.debug.panic("whoopsie", .{});
            };
        }

        return sum;
    }

    fn formatToMemoryLayout(buffer: *[36]u8, value: u36) void {
        _ = std.fmt.formatIntBuf(
            buffer,
            value,
            2,
            false,
            .{ .width = 36, .fill = '0' },
        );
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var memory = try parseAndLoadMemory(allocator, Memory.setWithBitmaskAt1);
    std.debug.print("Part 1: {}\n", .{memory.findSum()});
    memory.deinit();

    memory = try parseAndLoadMemory(allocator, Memory.setWithBitmaskAt2);
    std.debug.print("Part 2: {}\n", .{memory.findSum()});
    memory.deinit();
}

fn parseAndLoadMemory(allocator: *std.mem.Allocator, setMethod: anytype) !Memory {
    var memory = Memory.init(allocator);

    var line_iter = std.mem.tokenize(my_input, "\n");
    var current_mask: []const u8 = undefined;

    while (line_iter.next()) |line| {
        var token_iter = std.mem.tokenize(line, "= ");

        const key = token_iter.next().?;
        const value = token_iter.next().?;

        if (std.mem.eql(u8, key[0..3], "mem")) {
            const address_str = key[4 .. key.len - 1];
            const address = try std.fmt.parseUnsigned(usize, address_str, 10);

            var buffer: [36]u8 = undefined;
            Memory.formatToMemoryLayout(
                &buffer,
                try std.fmt.parseUnsigned(u36, value, 10),
            );

            try setMethod(&memory, address, &buffer, current_mask[0..36]);
        } else { // mask
            current_mask = value;
        }
    }

    return memory;
}
