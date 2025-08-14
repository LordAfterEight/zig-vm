const std = @import("std");
const opcodes = @import("opcodes.zig");
const mem_ = @import("memory.zig");

pub const CPU = struct {
    memory: mem_.Memory = mem_.Memory.init(),
    memory_ptr: u16 = 0x1000,
    stack_ptr: u8 = 0x00,

    a_reg: u16 = 0x0000,
    b_reg: u16 = 0x0000,
    c_reg: u16 = 0x0000,
    d_reg: u16 = 0x0000,

    halt_flag: bool = false,
    eq_flag: bool = false,

    pub fn init() CPU {
        return CPU {};
    }

    pub fn incr_mem_ptr(self: *CPU) !void {
        self.memory_ptr +%= 1;
    }

    pub fn incr_stack_ptr(self: *CPU) !void {
        self.stack_ptr +%= 1;
    }

    pub fn read_word_from_file(self: *CPU) u16 {
        var file = std.fs.cwd().openFile("ROM.bin", .{}) catch return opcodes.NO_OPERAT;

        file.seekTo(@as(u64, self.memory_ptr) * 2) catch return opcodes.NO_OPERAT;
        var buf: [2]u8 = undefined;
        _ = file.readAll(&buf) catch return opcodes.NO_OPERAT;

        var return_value: u16 = opcodes.NO_OPERAT;
        return_value = std.mem.readInt(u16, &buf, .big);

        std.log.info("Read instruction 0x{X} at address 0x{X}", .{return_value, self.memory_ptr});

        try self.incr_mem_ptr();
        defer file.close();
        return return_value;
    }

    pub fn update(self: *CPU) !void {
        const instruction = self.read_word_from_file();
        switch (instruction) {
            opcodes.LOAD_AREG => {
                const value = self.read_word_from_file();
                std.log.info("Loading A register with value: {}", .{value});
                self.a_reg = value;
            },
            opcodes.LOAD_BREG => {
                const value = self.read_word_from_file();
                std.log.info("Loading B register with value: {}", .{value});
                self.b_reg = value;
            },
            opcodes.LOAD_CREG => {
                const value = self.read_word_from_file();
                std.log.info("Loading C register with value: {}", .{value});
                self.c_reg = value;
            },
            opcodes.LOAD_DREG => {
                const value = self.read_word_from_file();
                std.log.info("Loading D register with value: {}", .{value});
                self.d_reg = value;
            },
            opcodes.STOR_AREG => {
            },
            opcodes.STOR_BREG => {
            },
            opcodes.STOR_CREG => {
            },
            opcodes.STOR_DREG => {
            },
            opcodes.JMP_TO_AD => {
                const address = self.read_word_from_file();
                std.log.info("Jumping to address: {}", .{address});
                self.memory_ptr = address;
            },
            opcodes.JMP_TO_SR => {
                self.memory.ram[self.stack_ptr] = self.memory_ptr + 1;
                const address = self.read_word_from_file();
                std.log.info("Jumping to subroutine at address: 0x{X}", .{address});
                self.memory_ptr = address;
                try self.incr_stack_ptr();
            },
            opcodes.RET_TO_OR => {
                self.stack_ptr -%= 1;
                const addr = self.memory.ram[self.stack_ptr];
                std.log.info("Returning to address 0x{X}", .{addr});
                self.memory_ptr = addr;
            },
            opcodes.INC_REG_V => {
                const reg = self.read_word_from_file();
                const val = self.read_word_from_file();
                switch (reg) {
                    0x41 => self.a_reg += val,
                    0x42 => self.b_reg += val,
                    0x43 => self.c_reg += val,
                    0x44 => self.d_reg += val,
                    else => {}
                }
            },
            opcodes.DEC_REG_V => {
                const reg = self.read_word_from_file();
                const val = self.read_word_from_file();
                switch (reg) {
                    0x41 => self.a_reg -= val,
                    0x42 => self.b_reg -= val,
                    0x43 => self.c_reg -= val,
                    0x44 => self.d_reg -= val,
                    else => {}
                }
            },
            opcodes.MUL_REG_V => {
                const reg = self.read_word_from_file();
                const val = self.read_word_from_file();
                switch (reg) {
                    0x41 => self.a_reg *= val,
                    0x42 => self.b_reg *= val,
                    0x43 => self.c_reg *= val,
                    0x44 => self.d_reg *= val,
                    else => {}
                }
            },
            opcodes.DIV_REG_V => {
                const reg = self.read_word_from_file();
                const val = self.read_word_from_file();
                switch (reg) {
                    0x41 => self.a_reg /= val,
                    0x42 => self.b_reg /= val,
                    0x43 => self.c_reg /= val,
                    0x44 => self.d_reg /= val,
                    else => {}
                }
            },
            opcodes.JUMP_IFEQ => {
                switch (self.eq_flag) {
                    true  => self.memory_ptr = self.read_word_from_file(),
                    false => {}
                }
            },
            opcodes.JUMP_INEQ => {
                switch (self.eq_flag) {
                    false => self.memory_ptr = self.read_word_from_file(),
                    true  => {}
                }
            },
            opcodes.COMP_REGS => {
                var val1 = self.read_word_from_file();
                var val2 = self.read_word_from_file();

                switch (val1) {
                    0x41 => val1 = self.a_reg,
                    0x42 => val1 = self.b_reg,
                    0x43 => val1 = self.c_reg,
                    0x44 => val1 = self.d_reg,
                    else => {}
                }

                switch (val2) {
                    0x41 => val2 = self.a_reg,
                    0x42 => val2 = self.b_reg,
                    0x43 => val2 = self.c_reg,
                    0x44 => val2 = self.d_reg,
                    else => {}
                }

                std.log.info("Comparing {} with {}", .{val1, val2});
                if (val1 == val2) {
                    self.eq_flag = true;
                }
            },
            opcodes.NO_OPERAT => {
                std.log.info("Doing nothing.", .{});
            },
            opcodes.HALT_LOOP => {
                std.log.info("Halting execution.", .{});
                //std.process.exit(0);
                self.halt_flag = true;
            },
            else => {},
        }
    }
};
