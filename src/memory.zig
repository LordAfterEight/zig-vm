const std = @import("std");
const opcodes = @import("opcodes.zig");

pub const Memory = struct {
    ram: [0xFFFF]u16 = [_]u16{0} ** 0xFFFF,

    pub fn init() Memory {
        return Memory{};
    }
};
