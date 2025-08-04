const std = @import("std");
const opcodes = @import("opcodes.zig");

pub const Memory = struct {
    rom: [0xFFFF + 1]u16 = [_]u16{0} ** (0xFFFF + 1),
    ram: [0xFF]u16 = [_]u16{0} ** 0xFF,

    pub fn init() Memory {
        return Memory{};
    }

    pub fn set_address(self: *Memory, value: u16, address: u16, mem: u2) void {
        switch (mem) {
            1 => self.rom[address] = value,
            2 => self.ram[address] = value,
            0 => std.log.info("Ignoring write to address {x}", .{address}),
        }
    }
};
