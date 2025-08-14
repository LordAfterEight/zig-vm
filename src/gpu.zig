const std = @import("std");
const sfml = @cImport ({
    @cInclude("CSFML/Graphics.h");
    @cInclude("CSFML/Window.h");
    @cInclude("CSFML/System.h");
});

const SCALING = 1.0;
const mode = sfml.sfVideoMode{
    .bitsPerPixel = 32,
    .size = .{ .x = 960 * SCALING, .y = 540 * SCALING },
};

pub const GPU = struct {
    window: *sfml.sfRenderWindow,
    buf_ptr: u16 = 0x300,

    pub fn init() !GPU {
        const window = sfml.sfRenderWindow_create(mode, "ZVM", sfml.sfClose | sfml.sfResize, sfml.sfWindowed, null);
        return GPU {
            .window = window.?,
        };
    }

    pub fn handle_window_events(self: *GPU) void {
        var event: sfml.sfEvent = undefined;
        while (sfml.sfRenderWindow_pollEvent(self.window, &event)) {
            if (event.type == sfml.sfEvtClosed) {
                sfml.sfRenderWindow_close(self.window);
            }
        }
    }

    pub fn deinit(self: *GPU) void {
        sfml.sfRenderWindow_destroy(self.window);
    }

    pub fn update(self: *GPU) void {
        self.handle_window_events();
        self.render();
    }

    pub fn render(self: *GPU) void {
        sfml.sfRenderWindow_display(self.window);
    }
};
