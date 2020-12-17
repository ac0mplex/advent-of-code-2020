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
const GRIDS = 1 + 2 * NUM_OF_CYCLES;

const HyperCube = struct {
    _cube: [GRIDS][LAYERS][ROWS][COLUMNS]u8 = undefined,

    fn create() HyperCube {
        var cube = HyperCube{};

        for (cube._cube) |grid, v| {
            for (grid) |layer, z| {
                for (layer) |row, y| {
                    for (row) |_, x| {
                        cube.setAt(x, y, z, v, '.');
                    }
                }
            }
        }

        for (my_input) |row, y| {
            for (row) |state, x| {
                cube.setAt(
                    x + COLUMNS / 2 - my_input[0].len / 2,
                    y + ROWS / 2 - my_input.len / 2,
                    LAYERS / 2,
                    GRIDS / 2,
                    state,
                );
            }
        }

        return cube;
    }

    fn setAt(self: *HyperCube, x: usize, y: usize, z: usize, v: usize, state: u8) void {
        self._cube[v][z][y][x] = state;
    }

    fn getAt(self: HyperCube, x: usize, y: usize, z: usize, v: usize) u8 {
        return self._cube[v][z][y][x];
    }

    fn doCycle(self: *HyperCube, other: HyperCube) void {
        var v: usize = 0;
        while (v < GRIDS) : (v += 1) {
            var z: usize = 0;
            while (z < LAYERS) : (z += 1) {
                var y: usize = 0;
                while (y < ROWS) : (y += 1) {
                    var x: usize = 0;
                    while (x < COLUMNS) : (x += 1) {
                        const neighbors = other.countNeighbors(x, y, z, v);
                        const cur_state = other.getAt(x, y, z, v);

                        if (cur_state == '#') {
                            if (neighbors < 2 or neighbors > 3) {
                                self.setAt(x, y, z, v, '.');
                            }
                        } else { // inactive
                            if (neighbors == 3) {
                                self.setAt(x, y, z, v, '#');
                            }
                        }
                    }
                }
            }
        }
    }

    fn countNeighbors(self: HyperCube, x: usize, y: usize, z: usize, v: usize) usize {
        var ix = @intCast(isize, x);
        var iy = @intCast(isize, y);
        var iz = @intCast(isize, z);
        var iv = @intCast(isize, v);
        var neighbors: usize = 0;

        var dv: isize = -1;
        while (dv <= 1) : (dv += 1) {
            if (iv + dv < 0 or iv + dv >= GRIDS) continue;

            var dz: isize = -1;
            while (dz <= 1) : (dz += 1) {
                if (iz + dz < 0 or iz + dz >= LAYERS) continue;

                var dy: isize = -1;
                while (dy <= 1) : (dy += 1) {
                    if (iy + dy < 0 or iy + dy >= ROWS) continue;

                    var dx: isize = -1;
                    while (dx <= 1) : (dx += 1) {
                        if (ix + dx < 0 or ix + dx >= COLUMNS) continue;
                        if (dx == 0 and dy == 0 and dz == 0 and dv == 0) continue;

                        neighbors += @boolToInt(self.getAt(
                            @intCast(usize, ix + dx),
                            @intCast(usize, iy + dy),
                            @intCast(usize, iz + dz),
                            @intCast(usize, iv + dv),
                        ) == '#');
                    }
                }
            }
        }

        return neighbors;
    }

    fn countActive(self: HyperCube) usize {
        var active: usize = 0;

        for (self._cube) |grid| {
            for (grid) |layer| {
                for (layer) |row| {
                    for (row) |state| {
                        active += @boolToInt(state == '#');
                    }
                }
            }
        }

        return active;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var cube = HyperCube.create();
    var tmp_cube = HyperCube.create();

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        cube.doCycle(tmp_cube);
        tmp_cube = cube;
    }

    std.debug.print("Part 1: {}\n", .{cube.countActive()});
}
