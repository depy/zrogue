const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const Allocator = std.mem.Allocator;

const screenWidth = 800;
const screenHeight = 600;
const cellSize = 20;
const screenCols: i32 = screenWidth / cellSize;
const screenRows: i32 = screenHeight / cellSize;

const mapRows = 50;
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

    pub fn draw(self: Player) void {
        var x = playerX;
        var y = playerY;

        if (self.x < screenCols / 2) {
            x = self.x;
        } else if (self.x > mapCols - screenCols / 2) {
            x = screenCols - (mapCols - self.x);
        }

        if (self.y < screenRows / 2) {
            y = self.y;
        } else if (self.y > mapRows - screenRows / 2) {
            y = screenRows - (mapRows - self.y);
        }

        rl.drawText(self.char, x * cellSize, y * cellSize, 28, self.fg);
    }

    pub fn move(self: *Player, d: Dir) void {
        self.x += d.toPos().x;
        self.y += d.toPos().y;

        if (self.x < 1) self.x = 1;
        if (self.x >= mapCols - 1) self.x = mapCols - 2;
        if (self.y < 1) self.y = 1;
        if (self.y >= mapRows - 1) self.y = mapRows - 2;
    }

    pub fn calculateWindow(p: Player) Rect {
        const startRow: i32 = math.clamp(p.y - screenRows / 2, 0, mapRows - screenRows);
        const endRow: i32 = math.clamp(p.y + screenRows / 2, screenRows, mapRows);
        const startCol: i32 = math.clamp(p.x - screenCols / 2, 0, mapCols - screenCols);
        const endCol: i32 = math.clamp(p.x + screenCols / 2, screenCols, mapCols);

        return Rect{
            .topLeft = Pos{ .x = startCol, .y = startRow },
            .bottomRight = Pos{ .x = endCol, .y = endRow },
        };
    }
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
        for (startRow..endRow, 0..) |row, j| {
            const start = row * mapCols + startCol;
            const end = row * mapCols + endCol;
            const rowWindow = self.tiles[start..end];

            for (rowWindow, 0..) |tile, i| {
                const x = @as(i32, @intCast(i)) * cellSize;
                const y = @as(i32, @intCast(j)) * cellSize;
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

fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.black);

    // Draw map
    const w = player.calculateWindow();
    m.displayWindow(@intCast(w.topLeft.y), @intCast(w.bottomRight.y), @intCast(w.topLeft.x), @intCast(w.bottomRight.x));

    // Draw entities
    for (entities) |entity| {
        rl.drawText(entity.char, entity.x * cellSize, entity.y * cellSize, 28, entity.fg);
    }

    // Draw player
    player.draw();
}

fn handleKeys() void {
    if (rl.isKeyDown(rl.KeyboardKey.key_g)) {
        player.move(Dir.Left);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_j)) {
        player.move(Dir.Right);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_y)) {
        player.move(Dir.Up);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_n)) {
        player.move(Dir.Down);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_t)) {
        player.move(Dir.UpLeft);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_u)) {
        player.move(Dir.UpRight);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_b)) {
        player.move(Dir.DownLeft);
    } else if (rl.isKeyDown(rl.KeyboardKey.key_m)) {
        player.move(Dir.DownRight);
    }
}

fn update() void {
    handleKeys();
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
