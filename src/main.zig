const c = @import("c.zig");
const Graphics = @import("Graphics.zig");

/// Should the second paddle be controlled by the computer?
const p1_use_ai = true;
const p1_up_key = c.SDL_SCANCODE_W;
const p1_down_key = c.SDL_SCANCODE_S;
const p2_use_ai = true;
const p2_up_key = c.SDL_SCANCODE_UP;
const p2_down_key = c.SDL_SCANCODE_DOWN;

var gfx = Graphics{};

var paddle1 = Paddle{ .x = 20, .y = (Graphics.height - Paddle.height) / 2 };
var paddle2 = Paddle{ .x = Graphics.width - Paddle.width - 20, .y = (Graphics.height - Paddle.height) / 2 };

var ball = Ball{ .x = (Graphics.width - Ball.size) / 2, .y = (Graphics.height - Ball.size) / 2 };

var p1_score: u8 = 0;
var p2_score: u8 = 0;

const Ball = struct {
    x: i32,
    y: i32,
    dx: i32 = speed,
    dy: i32 = speed,

    const size = 20;
    const speed = 4;

    fn reset(self: *Ball) void {
        self.x = (Graphics.width - size) / 2;
        self.y = (Graphics.height - size) / 2;
    }

    fn draw(self: Ball) void {
        gfx.fillRect(self.x, self.y, size, size);
    }
};

const Paddle = struct {
    x: i32,
    y: i32,
    dy: i32 = 0,

    const width = 20;
    const height = 80;
    const speed = 5;

    fn draw(self: Paddle) void {
        gfx.fillRect(self.x, self.y, width, height);
    }
};

fn tick() void {
    const keys = c.SDL_GetKeyboardState(null);
    if (p1_use_ai) {
        if (ball.dx < 0) {
            if (paddle1.y + Paddle.height / 2 < ball.y + Ball.size / 2) {
                paddle1.dy = Ball.speed;
            } else {
                paddle1.dy = -Ball.speed;
            }
        } else {
            paddle1.dy = 0;
        }
    } else {
        if (keys[p1_up_key] != 0) {
            paddle1.dy = -Paddle.speed;
        } else if (keys[c.SDL_SCANCODE_S] != 0) {
            paddle1.dy = Paddle.speed;
        } else {
            paddle1.dy = 0;
        }
    }

    if (p2_use_ai) {
        if (ball.dx > 0) {
            if (paddle2.y + Paddle.height / 2 < ball.y + Ball.size / 2) {
                paddle2.dy = Ball.speed;
            } else {
                paddle2.dy = -Ball.speed;
            }
        } else {
            paddle2.dy = 0;
        }
    } else {
        if (keys[p2_up_key] != 0) {
            paddle2.dy = -Paddle.speed;
        } else if (keys[p2_down_key] != 0) {
            paddle2.dy = Paddle.speed;
        } else {
            paddle2.dy = 0;
        }
    }

    paddle1.y += paddle1.dy;
    paddle2.y += paddle2.dy;

    if (paddle1.y < 0) {
        paddle1.y = 0;
    } else if (paddle1.y + Paddle.height > Graphics.height) {
        paddle1.y = Graphics.height - Paddle.height;
    }

    if (paddle2.y < 0) {
        paddle2.y = 0;
    } else if (paddle2.y + Paddle.height > Graphics.height) {
        paddle2.y = Graphics.height - Paddle.height;
    }

    ball.x += ball.dx;
    ball.y += ball.dy;

    if (ball.y < 0 or ball.y + Ball.size > Graphics.height) {
        ball.dy = -ball.dy;
    }

    if (((ball.x < paddle1.x + Paddle.width and ball.x - ball.dx >= paddle1.x + Paddle.width) and
        (ball.y > paddle1.y - Ball.size and ball.y < paddle1.y + Paddle.height)) or
        ((ball.x > paddle2.x - Ball.size and ball.x - ball.dx <= paddle2.x - Ball.size) and
        (ball.y > paddle2.y - Ball.size and ball.y < paddle2.y + Paddle.height)))
    {
        ball.dx = -ball.dx;
    }

    if (ball.x + Ball.size <= 0) {
        p2_score += 1;
        ball.reset();
    } else if (ball.x >= Graphics.width) {
        p1_score += 1;
        ball.reset();
    }
}

fn drawDigit(d: u4, x: i32, y: i32) void {
    const digits = [_]u16{ 0x7B6F, 0x4924, 0x73E7, 0x79E7, 0x49ED, 0x79CF, 0x7BCF, 0x4927, 0x7BEF, 0x79EF };
    const size = 10;
    for (0..5) |row| {
        for (0..3) |col| {
            if (digits[d] & (@as(u16, 1) << @intCast(u4, row * 3 + col)) != 0) {
                gfx.fillRect(x + @intCast(i32, col) * size, y + @intCast(i32, row) * size, size, size);
            }
        }
    }
}

fn drawScores() void {
    drawDigit(@intCast(u4, p1_score / 10), Graphics.width / 4 - 20, 10);
    drawDigit(@intCast(u4, p1_score % 10), Graphics.width / 4 + 20, 10);
    drawDigit(@intCast(u4, p2_score / 10), 3 * Graphics.width / 4 - 20, 10);
    drawDigit(@intCast(u4, p2_score % 10), 3 * Graphics.width / 4 + 20, 10);
}

fn drawCenterLine() void {
    const size = 10;
    var y: i32 = -size;
    while (y < Graphics.height) : (y += 3 * size) {
        gfx.fillRect(Graphics.width / 2 - size / 2, y, size, 2 * size);
    }
}

pub fn main() !void {
    try gfx.open("Pong");
    defer gfx.close();

    var quit: bool = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => quit = true,
                else => {},
            }
        }

        tick();

        gfx.setColor(0x00, 0x00, 0x00, 0x00);
        gfx.clear();
        gfx.setColor(0xff, 0xff, 0xff, 0xff);
        drawCenterLine();
        paddle1.draw();
        paddle2.draw();
        ball.draw();
        drawScores();
        gfx.flip();
    }
}
