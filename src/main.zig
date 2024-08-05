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

const fontSize = 18;

const playerX: i32 = screenCols / 2;
const playerY: i32 = screenRows / 2;

var player = Player{};

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
    x: i32 = 0,
    y: i32 = 0,
};

const Rect = struct {
    topLeft: Pos,
    bottomRight: Pos,
};

var m = Map.make();
const entities: [0]Entity = [_]Entity{};

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

const Player = struct {
    char: *const [1:0]u8 = "@",
    fg: rl.Color = rl.Color.yellow,
    x: i32 = playerX,
    y: i32 = playerY,
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
                fontSize,
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
                const x = @as(i32, @intCast(i)) * cellSize;
                const y = @as(i32, @intCast(row)) * cellSize;
                rl.drawText(tile.char, x, y, 22, tile.fg);
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

pub fn calculateWindow(p: Player) Rect {
    const startRow: i32 = p.y - screenRows / 2;
    const endRow: i32 = p.y + screenRows / 2;
    const startCol: i32 = p.x - screenCols / 2;
    const endCol: i32 = p.x + screenCols / 2;

    return Rect{
        .topLeft = Pos{ .x = startCol, .y = startRow },
        .bottomRight = Pos{ .x = endCol, .y = endRow },
    };
}

fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.black);

    // Draw map
    const w = calculateWindow(player);
    m.displayWindow(@intCast(w.topLeft.y), @intCast(w.bottomRight.y), @intCast(w.topLeft.x), @intCast(w.bottomRight.x));

    // Draw entities
    for (entities) |entity| {
        rl.drawText(entity.char, entity.x * cellSize, entity.y * cellSize, 28, entity.fg);
    }

    // Draw player
    rl.drawText(player.char, playerX * cellSize, playerY * cellSize, 28, player.fg);
}

fn update() void {
    if (rl.isKeyDown(rl.KeyboardKey.key_k)) {
        player.x += Dir.Right.toPos().x;
        player.y += Dir.Right.toPos().y;
    }
}

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
