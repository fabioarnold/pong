const std = @import("std");
const Graphics = @import("Graphics.zig");
const gfx = &@import("main.zig").gfx;
const config = @import("config.zig");
const Pong = @This();

const Ball = struct {
    x: i32 = (Graphics.width - size) / 2,
    y: i32 = (Graphics.width - size) / 2,
    dx: i32 = speed,
    dy: i32 = speed,

    const size = 20;
    const speed = 4;

    fn resetPosition(self: *Ball) void {
        self.x = (Graphics.width - size) / 2;
        self.y = (Graphics.height - size) / 2;
    }

    fn tick(ball: *Ball) void {
        ball.x += ball.dx;
        ball.y += ball.dy;

        if (ball.y < 0 or ball.y + Ball.size > Graphics.height) {
            ball.dy = -ball.dy;
        }
    }

    fn draw(self: Ball) void {
        gfx.fillRect(self.x, self.y, size, size);
    }
};

const Paddle = struct {
    x: i32,
    y: i32 = (Graphics.height - height) / 2,
    dy: i32 = 0,

    key_up: u32,
    key_down: u32,

    const width = 20;
    const height = 80;
    const speed = 5;

    fn handleInput(paddle: *Paddle, keys: [*]const u8) void {
        paddle.dy = 0;
        if (keys[paddle.key_up] != 0) paddle.dy -= Paddle.speed;
        if (keys[paddle.key_down] != 0) paddle.dy += Paddle.speed;
    }

    fn useAI(paddle: *Paddle, ball: Ball) void {
        const center_x = Graphics.width / 2;
        const diff_x = paddle.x + width / 2 - (ball.x + Ball.size / 2);
        const facing = (ball.dx > 0) == (diff_x > 0);
        if (facing and @abs(diff_x) < center_x) {
            if (paddle.y + Paddle.height / 2 < ball.y + Ball.size / 2) {
                paddle.dy = Ball.speed;
            } else {
                paddle.dy = -Ball.speed;
            }
        } else {
            paddle.dy = 0;
        }
    }

    fn tick(paddle: *Paddle) void {
        paddle.y += paddle.dy;
        paddle.y = std.math.clamp(paddle.y, 0, Graphics.height - height);
    }

    fn draw(self: Paddle) void {
        gfx.fillRect(self.x, self.y, width, height);
    }
};

const margin = 20;

paddle1: Paddle = Paddle{ .x = margin, .key_up = config.p1_key_up, .key_down = config.p1_key_down },
paddle2: Paddle = Paddle{ .x = Graphics.width - Paddle.width - margin, .key_up = config.p2_key_up, .key_down = config.p2_key_down },
ball: Ball = Ball{},
p1_score: u8 = 0,
p2_score: u8 = 0,

pub fn handleInput(pong: *Pong, keys: [*]const u8) void {
    if (config.p1_use_ai) pong.paddle1.useAI(pong.ball) else pong.paddle1.handleInput(keys);
    if (config.p2_use_ai) pong.paddle2.useAI(pong.ball) else pong.paddle2.handleInput(keys);
}

pub fn tick(pong: *Pong) void {
    pong.paddle1.tick();
    pong.paddle2.tick();
    pong.ball.tick();

    if (((pong.ball.x < pong.paddle1.x + Paddle.width and pong.ball.x - pong.ball.dx >= pong.paddle1.x + Paddle.width) and
        (pong.ball.y > pong.paddle1.y - Ball.size and pong.ball.y < pong.paddle1.y + Paddle.height)) or
        ((pong.ball.x > pong.paddle2.x - Ball.size and pong.ball.x - pong.ball.dx <= pong.paddle2.x - Ball.size) and
        (pong.ball.y > pong.paddle2.y - Ball.size and pong.ball.y < pong.paddle2.y + Paddle.height)))
    {
        pong.ball.dx = -pong.ball.dx;
    }

    if (pong.ball.x + Ball.size <= 0) {
        pong.p2_score += 1;
        pong.ball.resetPosition();
    } else if (pong.ball.x >= Graphics.width) {
        pong.p1_score += 1;
        pong.ball.resetPosition();
    }
}

fn drawDigit(d: u4, x: i32, y: i32) void {
    const digits = [_]u16{ 0x7B6F, 0x4924, 0x73E7, 0x79E7, 0x49ED, 0x79CF, 0x7BCF, 0x4927, 0x7BEF, 0x79EF };
    const size = 10;
    for (0..5) |row| {
        for (0..3) |col| {
            const i: u4 = @intCast(row * 3 + col);
            if (digits[d] >> i & 1 != 0) {
                gfx.fillRect(x + @as(i32, @intCast(col)) * size, y + @as(i32, @intCast(row)) * size, size, size);
            }
        }
    }
}

fn drawScores(p1_score: u8, p2_score: u8) void {
    drawDigit(@intCast(p1_score / 10), Graphics.width / 4 - 20, 10);
    drawDigit(@intCast(p1_score % 10), Graphics.width / 4 + 20, 10);
    drawDigit(@intCast(p2_score / 10), 3 * Graphics.width / 4 - 20, 10);
    drawDigit(@intCast(p2_score % 10), 3 * Graphics.width / 4 + 20, 10);
}

fn drawCenterLine() void {
    const size = 10;
    var y: i32 = -size;
    while (y < Graphics.height) : (y += 3 * size) {
        gfx.fillRect(Graphics.width / 2 - size / 2, y, size, 2 * size);
    }
}

pub fn draw(pong: Pong) void {
    gfx.setColor(0xff, 0xff, 0xff, 0xff);
    drawCenterLine();
    pong.paddle1.draw();
    pong.paddle2.draw();
    pong.ball.draw();
    drawScores(pong.p1_score, pong.p2_score);
}
