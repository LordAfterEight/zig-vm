const std = @import("std");
const opcodes = @import("opcodes.zig");
const cpu_ = @import("cpu.zig");
const mem = @import("memory.zig");
const gpu_ = @import("gpu.zig");
const sfml = @cImport({
    @cInclude("CSFML/Graphics.h");
    @cInclude("CSFML/Window.h");
    @cInclude("CSFML/System.h");
});

const SCALING = 1.0;

pub fn main() !void {

    var gpu = try gpu_.GPU.init();
    defer gpu.deinit();

    var cpu = cpu_.CPU.init();

    std.log.info("Starting VM", .{});

    while (sfml.sfRenderWindow_isOpen(gpu.window)) {
        var event: sfml.sfEvent = undefined;
        sfml.sfRenderWindow_clear(gpu.window, sfml.sfBlack);
        var ram_usage: f32 = 0.0;
        var addresses_used: f32 = 0.0;

        for (cpu.memory.ram) |value| {
            if (value != 0) {
                addresses_used += 1.0;
            }
        }

        ram_usage = addresses_used * 100.0 / 0xFFFF.0;

        std.log.info("{s}\n{s}{X}\n{s}{X}\n{s}{X}\n{s}{d}\n{s}{d}\n{s}{d}\n{s}{d}\n{s}{X}\n{s}{d:.2}% | {d:.2}kiB/128kiB\n\n{s}\n", .{
            "\x1b[2J\x1b[H",
            "MP: 0x",
            cpu.memory_ptr,
            "SP: 0x",
            cpu.stack_ptr,
            "GP: 0x",
            cpu.gpu_buf_ptr,
            "A Register: ",
            cpu.a_reg,
            "B Register: ",
            cpu.b_reg,
            "C Register: ",
            cpu.c_reg,
            "D Register: ",
            cpu.d_reg,
            "G Register: 0x",
            cpu.g_reg,
            "RAM usage: ",
            ram_usage,
            addresses_used * 2.0 / 1024.0,
            "Actions: "
        });

        if (!cpu.halt_flag and !cpu.input_flag) {
            cpu.update(&gpu) catch std.log.info("Error Occured!", .{});
        } else {
            std.log.info("Halt flag true", .{});
        }

        while (sfml.sfRenderWindow_pollEvent(gpu.window, &event)) {
            if (sfml.sfKeyboard_isKeyPressed(sfml.sfKeyEscape)) {
                std.process.exit(0);
            }
            if (sfml.sfKeyboard_isKeyPressed(sfml.sfKeyF11)) {
                try gpu.toggle_fullscreen();
                std.Thread.sleep(250_000_000);
            }
            if (event.type == sfml.sfEvtClosed) {
                sfml.sfRenderWindow_close(gpu.window);
            }
            if (event.type == sfml.sfEvtTextEntered and cpu.input_flag) {
                try cpu.handle_input(event.text.unicode);
            }
        }
        try gpu.update();
        //std.Thread.sleep(100_000_000);
    }
}
