const std = @import("std");

const my_input = [_]*const [8]u8{
    "###...#.",
    ".##.####",
    ".####.##",
    "###.###.",
    ".##.####",
    "#.##..#.",
    "##.####.",
    ".####.#.",
};

const NUM_OF_CYCLES = 6;

const ROWS = my_input.len + NUM_OF_CYCLES * 2;
const COLUMNS = my_input[0].len + NUM_OF_CYCLES * 2;
const LAYERS = 1 + 2 * NUM_OF_CYCLES;

const Grid = struct {
    _grid: [LAYERS][ROWS][COLUMNS]u8 = undefined,

    fn create() Grid {
        var grid = Grid{};

        for (grid._grid) |layer, z| {
            for (layer) |row, y| {
                for (row) |_, x| {
                    grid.setAt(x, y, z, '.');
                }
            }
        }

        for (my_input) |row, y| {
            for (row) |state, x| {
                grid.setAt(
                    x + COLUMNS / 2 - my_input[0].len / 2,
                    y + ROWS / 2 - my_input.len / 2,
                    LAYERS / 2,
                    state,
                );
            }
        }

        return grid;
    }

    fn setAt(self: *Grid, x: usize, y: usize, z: usize, state: u8) void {
        self._grid[z][y][x] = state;
    }

    fn getAt(self: Grid, x: usize, y: usize, z: usize) u8 {
        return self._grid[z][y][x];
    }

    fn doCycle(self: *Grid, other: Grid) void {
        var z: usize = 0;
        while (z < LAYERS) : (z += 1) {
            var y: usize = 0;
            while (y < ROWS) : (y += 1) {
                var x: usize = 0;
                while (x < COLUMNS) : (x += 1) {
                    const neighbors = other.countNeighbors(x, y, z);
                    const cur_state = other.getAt(x, y, z);

                    if (cur_state == '#') {
                        if (neighbors < 2 or neighbors > 3) {
                            self.setAt(x, y, z, '.');
                        }
                    } else { // inactive
                        if (neighbors == 3) {
                            self.setAt(x, y, z, '#');
                        }
                    }
                }
            }
        }
    }

    fn countNeighbors(self: Grid, x: usize, y: usize, z: usize) usize {
        var ix = @intCast(isize, x);
        var iy = @intCast(isize, y);
        var iz = @intCast(isize, z);
        var neighbors: usize = 0;

        var dz: isize = -1;
        while (dz <= 1) : (dz += 1) {
            if (iz + dz < 0 or iz + dz >= LAYERS) continue;

            var dy: isize = -1;
            while (dy <= 1) : (dy += 1) {
                if (iy + dy < 0 or iy + dy >= ROWS) continue;

                var dx: isize = -1;
                while (dx <= 1) : (dx += 1) {
                    if (ix + dx < 0 or ix + dx >= COLUMNS) continue;
                    if (dx == 0 and dy == 0 and dz == 0) continue;

                    neighbors += @boolToInt(self.getAt(
                        @intCast(usize, ix + dx),
                        @intCast(usize, iy + dy),
                        @intCast(usize, iz + dz),
                    ) == '#');
                }
            }
        }

        return neighbors;
    }

    fn countActive(self: Grid) usize {
        var active: usize = 0;

        for (self._grid) |layer, z| {
            for (layer) |row, y| {
                for (row) |state, x| {
                    active += @boolToInt(state == '#');
                }
            }
        }

        return active;
    }

    pub fn format(
        self: Grid,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try std.fmt.format(writer, "=== GRID ===\n", .{});
        for (self._grid) |layer, z| {
            try std.fmt.format(writer, "LAYER: {}\n", .{z});
            for (layer) |row, y| {
                try std.fmt.format(writer, "{}\n", .{row});
            }
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var grid = Grid.create();
    var tmp_grid = Grid.create();

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        grid.doCycle(tmp_grid);
        tmp_grid = grid;
    }

    std.debug.print("Part 1: {}\n", .{grid.countActive()});
}
