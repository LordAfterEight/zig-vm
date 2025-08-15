const std = @import("std");
const opcodes = @import("opcodes.zig");
const sfml = @cImport ({
    @cInclude("CSFML/Graphics.h");
    @cInclude("CSFML/Window.h");
    @cInclude("CSFML/System.h");
});

const FRAME_SIZE_X = 120;
const FRAME_SIZE_Y = 38;

const mode = sfml.sfVideoMode{
    .bitsPerPixel = 32,
    .size = .{ .x = 960, .y = 540 },
};

pub const GPU = struct {
    window: *sfml.sfRenderWindow,
    scaling: u32 = 1,
    fullscreen: bool = false,
    buf_ptr: u16 = 0x300,
    draw_mode: bool = false,
    cursor: Cursor = Cursor.init(),
    cursor_x: u8 = 0,
    cursor_y: u8 = 0,
    font: *sfml.sfFont,
    font_size: u32,
    frame_buffer: [FRAME_SIZE_X][FRAME_SIZE_Y]u8 = [_][FRAME_SIZE_Y]u8{ [_]u8{' '} ** FRAME_SIZE_Y } ** FRAME_SIZE_X,
    color_buffer: [FRAME_SIZE_X][FRAME_SIZE_Y]u8 = [_][FRAME_SIZE_Y]u8{ [_]u8{0x0} ** FRAME_SIZE_Y } ** FRAME_SIZE_X,
    text: *sfml.sfText,

    pub fn init() !GPU {
        const font_size = 12;
        const window = sfml.sfRenderWindow_create(mode, "ZVM", sfml.sfClose | sfml.sfResize, sfml.sfWindowed, null);
        const font = sfml.sfFont_createFromFile("src/res/fonts/BigBlueTerminal/BigBlueTermPlusNerdFontMono-Regular.ttf");
        const text = sfml.sfText_create(font);

        sfml.sfText_setCharacterSize(text, font_size);
        sfml.sfRenderWindow_setKeyRepeatEnabled(window, false);

        return GPU {
            .window = window.?,
            .font = font.?,
            .text = text.?,
            .font_size = font_size,
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

    pub fn toggle_fullscreen(self: *GPU) !void {
        self.fullscreen = !self.fullscreen;

        switch (self.fullscreen) {
            true => {
                sfml.sfRenderWindow_destroy(self.window);
                self.window = sfml.sfRenderWindow_create(mode, "ZVM", sfml.sfClose | sfml.sfResize, sfml.sfFullscreen, null).?;
                self.scaling = 2;
                self.font_size = 12 * self.scaling;
                sfml.sfText_setCharacterSize(self.text, self.font_size);
                sfml.sfRenderWindow_setKeyRepeatEnabled(self.window, false);
            },
            false => {
                sfml.sfRenderWindow_destroy(self.window);
                self.window = sfml.sfRenderWindow_create(mode, "ZVM", sfml.sfClose | sfml.sfResize, sfml.sfWindowed, null).?;
                self.scaling = 1;
                self.font_size = 12 * self.scaling;
                sfml.sfText_setCharacterSize(self.text, self.font_size);
                sfml.sfRenderWindow_setKeyRepeatEnabled(self.window, false);
            },
        }
    }

    pub fn read_word_from_file(self: *GPU) u16 {
        var file = std.fs.cwd().openFile("ROM.bin", .{}) catch return opcodes.NO_OPERAT;
        defer file.close();

        file.seekTo(@as(u64, self.buf_ptr) * 2) catch return opcodes.NO_OPERAT;
        var buf: [2]u8 = undefined;
        _ = file.readAll(&buf) catch return opcodes.NO_OPERAT;

        var return_value: u16 = opcodes.NO_OPERAT;
        return_value = std.mem.readInt(u16, &buf, .big);


        if (return_value != 0xA000) {
            try self.incr_buf_ptr();
        }
        return return_value;
    }

    pub fn deinit(self: *GPU) void {
        sfml.sfRenderWindow_destroy(self.window);
        sfml.sfFont_destroy(self.font);
        sfml.sfText_destroy(self.text);
    }

    pub fn incr_buf_ptr(self: *GPU) !void {
        self.buf_ptr +%= 1;
    }

    pub fn move_cursor(self: *GPU) !void {
        if (self.cursor_x < FRAME_SIZE_X) {
            self.cursor_x += 1;
        } else {
            self.cursor_x = 0;
            self.cursor_y += 1;
        }
    }

    pub fn update(self: *GPU) void {
        const instruction = self.read_word_from_file();
        switch (self.draw_mode) {
            true => {
                const char: u8 = @intCast(instruction & 0xFF);
                const color: u8 = @intCast(instruction >> 8);

                std.log.info("Found character: {c} | {X} with color {X}", .{char, char, color});

                switch (char) {
                    '`' => self.draw_mode = false,
                    0x20...0x5F, 0x61...0x7F => {
                        self.frame_buffer[self.cursor_x][self.cursor_y] = char;
                        self.color_buffer[self.cursor_x][self.cursor_y] = color;
                        try self.move_cursor();
                    },
                    else => {}
                }
            },
            false => {
                switch (instruction) {
                    opcodes.GPU_NEW_LINE => {
                        self.cursor_y += 1;
                        self.cursor_x = 0;
                    },
                    opcodes.GPU_DRAW_TEXT => {
                        self.draw_mode = true;
                    },
                    opcodes.GPU_NO_OPERAT => {
                        std.log.info("Doing nothing", .{});
                    },
                    else => {}
                }
            }
        }
        self.handle_window_events();
        self.cursor.update();
        self.render();
    }

    pub fn render(self: *GPU) void {
        sfml.sfRenderWindow_clear(self.window, sfml.sfBlack);

        const cursor = sfml.sfText_create(self.font);

        defer sfml.sfText_destroy(cursor);

        sfml.sfText_setCharacterSize(cursor, self.font_size);

        sfml.sfText_setString(cursor, self.cursor.cursor_char);

        sfml.sfText_setPosition(cursor, sfml.sfVector2f{
            .x = @floatFromInt(self.cursor_x * (self.font_size - 4)),
            .y = @floatFromInt(self.cursor_y * (self.font_size + 2)),
        });
        sfml.sfRenderWindow_drawText(self.window, cursor, null);

        for (0..self.frame_buffer[0].len) |y| {
            for (0..self.frame_buffer.len) |x| {
                const ch: u8 = self.frame_buffer[x][y];
                const col: u8 = self.color_buffer[x][y];
                var str: [2]u8 = .{ ch, 0 }; // Null-terminated string for CSFML
                sfml.sfText_setString(self.text, &str[0]);
                sfml.sfText_setPosition(self.text, sfml.sfVector2f{
                    .x = @floatFromInt(x * (self.font_size - 4)),
                    .y = @floatFromInt(y * (self.font_size + 2)),
                });

                switch (col) {
                    0xA => sfml.sfText_setFillColor(self.text, sfml.sfWhite),
                    0xB => sfml.sfText_setFillColor(self.text, sfml.sfRed),
                    0xC => sfml.sfText_setFillColor(self.text, sfml.sfGreen),
                    0xD => sfml.sfText_setFillColor(self.text, sfml.sfBlue),
                    0xE => sfml.sfText_setFillColor(self.text, sfml.sfCyan),
                    0xF => sfml.sfText_setFillColor(self.text, sfml.sfMagenta),
                    else => sfml.sfText_setFillColor(self.text, sfml.sfWhite)
                }

                sfml.sfRenderWindow_drawText(self.window, self.text, null);
            }
        }
        sfml.sfRenderWindow_display(self.window);
    }
};

pub const Cursor = struct {
    cycle_counter: u16 = 0,
    cursor_char: *const [1]u8 = "_",

    pub fn init() Cursor {
        return Cursor {};
    }

    pub fn update(self: *Cursor) void {
        if (self.cycle_counter < 0x300) {
            self.cycle_counter += 1;
        } else {
            self.cycle_counter = 0;
        }

        if (self.cycle_counter > 0x300 / 2) {
            self.cursor_char = "_";
        } else {
            self.cursor_char = " ";
        }
    }
};
