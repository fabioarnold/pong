const c = @import("c.zig");
const Graphics = @import("Graphics.zig");
const Pong = @import("Pong.zig");

pub var gfx = Graphics{};

pub fn main() !void {
    try gfx.open("Pong");
    defer gfx.close();

    var pong = Pong{};

    var quit: bool = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => quit = true,
                c.SDL_KEYDOWN => quit = event.key.keysym.sym == c.SDLK_ESCAPE,
                else => {},
            }
        }

        pong.handleInput(c.SDL_GetKeyboardState(null));
        pong.tick();

        gfx.setColor(0x00, 0x00, 0x00, 0x00);
        gfx.clear();
        pong.draw();
        gfx.flip();
    }
}
