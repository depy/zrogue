const std = @import("std");
const rl = @import("raylib");
const Allocator = std.mem.Allocator;

const screenWidth = 800;
const screenHeight = 600;
const cellSize = 20;
const screenCols: i32 = screenWidth / cellSize;
const screenRows: i32 = screenHeight / cellSize;

const mapRows = 80;
const mapCols = 100;
const mapLen = mapRows * mapCols;

var m = Map.make();
const entities: [1]Entity = [_]Entity{player};

const Tile = struct {
    char: *const [1:0]u8 = " ",
    fg: rl.Color = rl.Color.white,
    bg: rl.Color = rl.Color.black,
};

const Wall = Tile{ .char = "#", .fg = rl.Color.gray };

const Entity = struct {
    char: *const [1:0]u8 = " ",
    fg: rl.Color = rl.Color.white,
    bg: rl.Color = rl.Color.black,
    x: i32 = 0,
    y: i32 = 0,
};

const player = Entity{
    .char = "@",
    .fg = rl.Color.yellow,
    .x = 1,
    .y = 1,
};

const Map = struct {
    tiles: [mapLen]Tile,

    pub fn make() Map {
        return Map{ .tiles = [_]Tile{Tile{}} ** mapLen };
    }

    pub fn display(self: Map) void {
        for (self.tiles, 0..) |tile, i| {
            const row: i32 = @divTrunc(@as(i32, @intCast(i)), mapCols);
            const col = @rem(@as(i32, @intCast(i)), mapCols);
            rl.drawText(
                tile.char,
                col * cellSize,
                row * cellSize,
                28,
                tile.fg,
            );
        }
    }

    pub fn displayWindow(self: Map, startRow: usize, endRow: usize, startCol: usize, endCol: usize) void {
        for (startRow..endRow) |row| {
            const start = row * mapCols + startCol;
            const end = row * mapCols + endCol;
            const rowWindow = self.tiles[start..end];

            for (rowWindow, 0..) |tile, i| {
                rl.drawText(
                    tile.char,
                    @as(i32, @intCast(i)) * cellSize,
                    @as(i32, @intCast(row)) * cellSize,
                    22,
                    tile.fg,
                );
            }
        }
    }

    pub fn generate(self: *Map) void {
        for (self.tiles, 0..) |_, i| {
            if (i < mapCols or
                i % mapCols == 0 or
                i % mapCols == mapCols - 1 or
                i > mapLen - mapCols)
            {
                self.tiles[i] = Wall;
            }
        }
    }
};

const Dir = enum {
    Up,
    Down,
    Left,
    Right,
    UpLeft,
    UpRight,
    DownLeft,
    DownRight,

    pub fn toPos(self: Dir) Pos {
        switch (self) {
            Dir.Up => return Pos{ .x = 0, .y = -1 },
            Dir.Down => return Pos{ .x = 0, .y = 1 },
            Dir.Left => return Pos{ .x = -1, .y = 0 },
            Dir.Right => return Pos{ .x = 1, .y = 0 },
            Dir.UpLeft => return Pos{ .x = -1, .y = -1 },
            Dir.UpRight => return Pos{ .x = 1, .y = -1 },
            Dir.DownLeft => return Pos{ .x = -1, .y = 1 },
            Dir.DownRight => return Pos{ .x = 1, .y = 1 },
        }
    }
};

const Pos = struct {
    x: u32 = 0,
    y: u32 = 0,
};

fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.black);

    m.displayWindow(0, 30, 0, 40);
    for (entities) |entity| {
        rl.drawText(
            entity.char,
            entity.x * cellSize,
            entity.y * cellSize,
            28,
            entity.fg,
        );
    }
}

fn update() void {}

pub fn main() void {
    rl.initWindow(screenWidth, screenHeight, "zrogue");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    m.generate();

    while (!rl.windowShouldClose()) {
        update();
        draw();
    }
}
