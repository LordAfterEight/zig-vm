const std = @import("std");
const opcodes = @import("opcodes.zig");
const mem_ = @import("memory.zig");

pub const CPU = struct {
    memory: mem_.Memory = mem_.Memory.init(),
    memory_ptr: u16 = 0x0000,
    stack_ptr: u16 = 0x0000,

    a_reg: u16 = 0x0000,
    b_reg: u16 = 0x0000,
    c_reg: u16 = 0x0000,
    d_reg: u16 = 0x0000,

    pub fn init() CPU {
        return CPU {};
    }

    pub fn incr_mem_ptr(self: *CPU) !void {
        self.memory_ptr +%= 1;
    }

    pub fn incr_stack_ptr(self: *CPU) !void {
        self.stack_ptr +%= 1;
    }

    pub fn update(self: *CPU) !void {
        const instruction = self.memory.rom[self.memory_ptr];
        switch (instruction) {
            opcodes.LOAD_AREG => {
                std.log.info("Loading A register with value: {}", .{self.memory.rom[self.memory_ptr + 1]});
                const value = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.a_reg = value;
            },
            opcodes.LOAD_BREG => {
                std.log.info("Loading B register with value: {}", .{self.memory.rom[self.memory_ptr + 1]});
                const value = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.b_reg = value;
            },
            opcodes.LOAD_CREG => {
                std.log.info("Loading C register with value: {}", .{self.memory.rom[self.memory_ptr + 1]});
                const value = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.c_reg = value;
            },
            opcodes.LOAD_DREG => {
                std.log.info("Loading D register with value: {}", .{self.memory.rom[self.memory_ptr + 1]});
                const value = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.d_reg = value;
            },
            opcodes.STOR_AREG => {
                std.log.info("Storing A register value {} to address: {}", .{self.a_reg, self.memory.rom[self.memory_ptr + 1]});
                const address = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.memory.rom[address] = self.a_reg;
            },
            opcodes.STOR_BREG => {
                std.log.info("Storing B register value {} to address: {}", .{self.b_reg, self.memory.rom[self.memory_ptr + 1]});
                const address = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.memory.rom[address] = self.b_reg;
            },
            opcodes.STOR_CREG => {
                std.log.info("Storing C register value {} to address: {}", .{self.c_reg, self.memory.rom[self.memory_ptr + 1]});
                const address = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.memory.rom[address] = self.c_reg;
            },
            opcodes.STOR_DREG => {
                std.log.info("Storing D register value {} to address: {}", .{self.d_reg, self.memory.rom[self.memory_ptr + 1]});
                const address = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.memory.rom[address] = self.d_reg;
            },
            opcodes.JMP_TO_AD => {
                std.log.info("Jumping to address: {}", .{self.memory.rom[self.memory_ptr + 1]});
                const address = self.memory.rom[self.memory_ptr + 1];
                try self.incr_mem_ptr();
                self.memory_ptr = address;
            },
            opcodes.JMP_TO_SR => {
                std.log.info("Jumping to subroutine at address: {}", .{self.memory.rom[self.memory_ptr + 1]});
                const address = self.memory.rom[self.memory_ptr + 1];
                self.memory.ram[self.stack_ptr] = self.memory_ptr + 1;
                self.memory_ptr = address;
                try self.incr_stack_ptr();
            },
            opcodes.HALT_LOOP => {
                std.log.info("Halting execution.", .{});
                while (true) {}
            },
            else => {},
        }
        try self.incr_mem_ptr();
    }
};
