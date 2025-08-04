const std = @import("std");
const opcodes = @import("opcodes.zig");
const cpu_ = @import("cpu.zig");

pub fn main() !void {
    var cpu = cpu_.CPU.init();

    std.log.info("Preprogramming memory...", .{});
    cpu.memory.rom[0x1000] = opcodes.LOAD_AREG;
    cpu.memory.rom[0x1001] = 0x1;
    cpu.memory.rom[0x1002] = opcodes.HALT_LOOP;

    std.log.info("Starting VM", .{});
    while (true) {
        try cpu.update();
    }
}
