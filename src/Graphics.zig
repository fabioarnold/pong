const c = @import("c.zig");

pub const width = 640;
pub const height = 480;

window: ?*c.SDL_Window = undefined,
renderer: ?*c.SDL_Renderer = undefined,

const Graphics = @This();

pub fn open(self: *Graphics, title: [:0]const u8) !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return error.SDLInitFailed;
    }
    errdefer c.SDL_Quit();

    self.window = c.SDL_CreateWindow(title, c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, width, height, 0);
    if (self.window == null) {
        return error.SDLCreateWindowFailed;
    }
    errdefer c.SDL_DestroyWindow(self.window);

    self.renderer = c.SDL_CreateRenderer(self.window, -1, c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC);
    if (self.renderer == null) {
        return error.SDLCreateRendererFailed;
    }
    errdefer c.SDL_DestroyRenderer(self.renderer);
}

pub fn close(self: Graphics) void {
    c.SDL_DestroyRenderer(self.renderer);
    c.SDL_DestroyWindow(self.window);
    c.SDL_Quit();
}

pub fn setColor(self: Graphics, r: u8, g: u8, b: u8, a: u8) void {
    _ = c.SDL_SetRenderDrawColor(self.renderer, r, g, b, a);
}

pub fn clear(self: Graphics) void {
    _ = c.SDL_RenderClear(self.renderer);
}

pub fn fillRect(self: Graphics, x: i32, y: i32, w: i32, h: i32) void {
    _ = c.SDL_RenderFillRect(self.renderer, &c.SDL_Rect{ .x = x, .y = y, .w = w, .h = h });
}

pub fn flip(self: Graphics) void {
    _ = c.SDL_RenderPresent(self.renderer);
}
