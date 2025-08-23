const std = @import("std");
const opcodes = @import("opcodes.zig");
const mem_ = @import("memory.zig");
const GPU = @import("gpu.zig");
const sfml = @cImport({
    @cInclude("CSFML/Window.h");
    @cInclude("CSFML/Graphics.h");
    @cInclude("CSFML/System.h");
});

pub const CPU = struct {
    memory: mem_.Memory = mem_.Memory.init(),
    memory_ptr: u16 = 0x1000,
    gpu_buf_ptr: u16 = 0x300,
    stack_ptr: u16 = 0x0,

    input_buffer_ptr: usize = 0x0,
    input_buffer: [100]u8 = undefined,

    a_reg: u16 = 0x0,
    b_reg: u16 = 0x0,
    c_reg: u16 = 0x0,
    d_reg: u16 = 0x0,

    g_reg: u16 = 0x0,

    halt_flag: bool = false,
    eq_flag: bool = false,
    input_flag: bool = false,

    pub fn init() CPU {
        return CPU{};
    }

    pub fn incr_mem_ptr(self: *CPU) void {
        self.memory_ptr +%= 1;
    }

    pub fn incr_stack_ptr(self: *CPU) void {
        self.stack_ptr +%= 1;
    }

    pub fn incr_gpu_buf_ptr(self: *CPU) void {
        if (self.gpu_buf_ptr < 0xFFF) {
            self.gpu_buf_ptr += 1;
        } else {
            self.gpu_buf_ptr = 0x300;
            for (0x300..0xFFF) |i| {
                self.write_word_to_file(opcodes.GPU_NO_OPERAT, @intCast(i)) catch {};
            }
        }
    }

    pub fn read_word_from_file(self: *CPU) u16 {
        var file = std.fs.cwd().openFile("ROM.bin", .{}) catch return opcodes.NO_OPERAT;
        defer file.close();

        file.seekTo(@as(u64, self.memory_ptr) * 2) catch return opcodes.NO_OPERAT;
        var buf: [2]u8 = undefined;
        _ = file.readAll(&buf) catch return opcodes.NO_OPERAT;

        var return_value: u16 = opcodes.NO_OPERAT;
        return_value = std.mem.readInt(u16, &buf, .big);

        std.log.info("Read instruction 0x{X} at address 0x{X}", .{ return_value, self.memory_ptr });

        self.incr_mem_ptr();
        return return_value;
    }

    pub fn read_word_from_file_at(address: u16) u16 {
        var file = std.fs.cwd().openFile("ROM.bin", .{}) catch return opcodes.NO_OPERAT;
        defer file.close();

        file.seekTo(@as(u64, address) * 2) catch return opcodes.NO_OPERAT;
        var buf: [2]u8 = undefined;
        _ = file.readAll(&buf) catch return opcodes.NO_OPERAT;

        var return_value: u16 = opcodes.NO_OPERAT;
        return_value = std.mem.readInt(u16, &buf, .big);

        std.log.info("Read instruction 0x{X} at address 0x{X}", .{ return_value, address });

        return return_value;
    }

    pub fn write_word_to_file(self: *CPU, value: u16, address: u16) !void {
        var file = try std.fs.cwd().createFile("ROM.bin", .{ .truncate = false });
        defer file.close();

        std.log.info("Write value 0x{X} to address 0x{X}", .{ value, address });

        try file.seekTo(@as(u64, address) * 2);
        var buf: [2]u8 = undefined;
        std.mem.writeInt(u16, &buf, value, .big);
        try file.writeAll(&buf);
        self.memory_ptr += 0;
    }

    pub fn gpu_print(self: *CPU, buffer: []const u8) !void {
        self.input_flag = false;
        try self.write_word_to_file(opcodes.GPU_DRAW_TEXT, self.gpu_buf_ptr);
        self.incr_gpu_buf_ptr();
        for (buffer) |character| {
            try self.write_word_to_file(character, self.gpu_buf_ptr);
            self.incr_gpu_buf_ptr();
        }
        try self.write_word_to_file(0x60, self.gpu_buf_ptr);
        self.incr_gpu_buf_ptr();
        std.log.info("GPU Print: {s}", .{buffer});
    }

    pub fn gpu_println(self: *CPU, buffer: []const u8) !void {
        try self.write_word_to_file(opcodes.GPU_NEW_LINE, self.gpu_buf_ptr);
        self.incr_gpu_buf_ptr();
        try self.gpu_print(buffer);
    }

    pub fn handle_input(self: *CPU, key: u32) !void {
        const char: u8 = @intCast(key);
        switch (char) {
            '\r', '\n' => {
                const string = self.input_buffer[0..self.input_buffer_ptr];
                if (std.mem.eql(u8, string, "shutdown")) {
                    std.process.exit(0);
                } else if (std.mem.eql(u8, string, "help")) {
                    try self.gpu_println("[CPU] => | help:");
                    try self.gpu_println("  - shutdown | Shutdown the system");
                    try self.gpu_println("  - help     | Show this help message");
                } else if (std.mem.eql(u8, string, "")) {} else {
                    try self.gpu_println("[CPU] => | Invalid command: ");
                    try self.gpu_print(string);
                }
                for (0..self.input_buffer.len) |i| {
                    self.input_buffer[i] = 0x0;
                    self.input_buffer_ptr = 0;
                }
                self.input_flag = false;
            },
            else => {
                self.input_buffer[self.input_buffer_ptr] = char;
                try self.write_word_to_file(opcodes.GPU_DRAW_TEXT, self.gpu_buf_ptr);
                self.incr_gpu_buf_ptr();
                try self.write_word_to_file(char, self.gpu_buf_ptr);
                self.incr_gpu_buf_ptr();
                try self.write_word_to_file(0x60, self.gpu_buf_ptr);
                self.incr_gpu_buf_ptr();
                self.input_buffer_ptr += 1;
            },
        }
    }

    pub fn update(self: *CPU, gpu: *GPU.GPU) !void {
        const instruction = self.read_word_from_file();
        switch (instruction) {
            opcodes.LOAD_AREG => {
                var value = self.read_word_from_file();
                if (value >> 12 == 0xF) {
                    value = read_word_from_file_at(value & 0xFFF);
                }
                std.log.info("Loading A register with value: {}", .{value});
                self.a_reg = value;
            },
            opcodes.LOAD_BREG => {
                var value = self.read_word_from_file();
                if (value >> 12 == 0xF) {
                    value = read_word_from_file_at(value & 0xFFF);
                }
                std.log.info("Loading B register with value: {}", .{value});
                self.b_reg = value;
            },
            opcodes.LOAD_CREG => {
                var value = self.read_word_from_file();
                if (value >> 12 == 0xF) {
                    value = read_word_from_file_at(value & 0xFFF);
                }
                std.log.info("Loading C register with value: {}", .{value});
                self.c_reg = value;
            },
            opcodes.LOAD_DREG => {
                var value = self.read_word_from_file();
                if (value >> 12 == 0xF) {
                    value = read_word_from_file_at(value & 0xFFF);
                }
                std.log.info("Loading D register with value: {}", .{value});
                self.d_reg = value;
            },
            opcodes.LOAD_GREG => {
                var value = self.read_word_from_file();
                std.log.info("Loading G register with value: {}", .{value});
                switch (value >> 12) {
                    0xE => {
                        gpu.int_flag = true;
                        switch (value) {
                            0xE0AA => value = self.a_reg,
                            0xE0BB => value = self.b_reg,
                            0xE0CC => value = self.c_reg,
                            0xE0DD => value = self.d_reg,
                            else => {},
                        }
                    },
                    0xF => {
                        gpu.int_flag = true;
                        switch (value) {
                            0xF000...0xF1FF => {
                                value = read_word_from_file_at(value & 0xFFF);
                            },
                            else => {},
                        }
                    },
                    else => {},
                }
                self.g_reg = value;
                std.log.info("Loading G register with value: 0x{X}", .{value});
            },
            opcodes.STOR_AREG => {
                try self.write_word_to_file(self.a_reg, self.read_word_from_file());
            },
            opcodes.STOR_BREG => {
                try self.write_word_to_file(self.b_reg, self.read_word_from_file());
            },
            opcodes.STOR_CREG => {
                try self.write_word_to_file(self.c_reg, self.read_word_from_file());
            },
            opcodes.STOR_DREG => {
                try self.write_word_to_file(self.d_reg, self.read_word_from_file());
            },
            opcodes.STOR_GREG => {
                try self.write_word_to_file(self.g_reg, self.gpu_buf_ptr);
                switch (self.g_reg) {
                    opcodes.GPU_RES_F_BUF => {
                        self.gpu_buf_ptr = 0x300;
                    },
                    opcodes.GPU_RESET_PTR => {
                        self.gpu_buf_ptr = 0x300;
                    },
                    opcodes.GPU_NO_OPERAT => {},
                    else => self.incr_gpu_buf_ptr(),
                }
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
                self.incr_stack_ptr();
            },
            opcodes.RET_TO_OR => {
                self.stack_ptr -%= 1;
                const addr = self.memory.ram[self.stack_ptr];
                std.log.info("Returning to address 0x{X}", .{addr});
                self.memory_ptr = addr;
            },
            opcodes.INC_REG_V => {
                const reg = self.read_word_from_file();
                var val = self.read_word_from_file();
                switch (val) {
                    0xE0AA => val = self.a_reg,
                    0xE0BB => val = self.b_reg,
                    0xE0CC => val = self.c_reg,
                    0xE0DD => val = self.d_reg,
                    else => {},
                }
                switch (reg) {
                    0x41 => self.a_reg += val,
                    0x42 => self.b_reg += val,
                    0x43 => self.c_reg += val,
                    0x44 => self.d_reg += val,
                    else => {},
                }
            },
            opcodes.DEC_REG_V => {
                const reg = self.read_word_from_file();
                var val = self.read_word_from_file();
                switch (val) {
                    0xE0AA => val = self.a_reg,
                    0xE0BB => val = self.b_reg,
                    0xE0CC => val = self.c_reg,
                    0xE0DD => val = self.d_reg,
                    else => {},
                }
                switch (reg) {
                    0x41 => self.a_reg -= val,
                    0x42 => self.b_reg -= val,
                    0x43 => self.c_reg -= val,
                    0x44 => self.d_reg -= val,
                    else => {},
                }
            },
            opcodes.MUL_REG_V => {
                const reg = self.read_word_from_file();
                var val = self.read_word_from_file();
                switch (val) {
                    0xE0AA => val = self.a_reg,
                    0xE0BB => val = self.b_reg,
                    0xE0CC => val = self.c_reg,
                    0xE0DD => val = self.d_reg,
                    else => {},
                }
                switch (reg) {
                    0x41 => self.a_reg *= val,
                    0x42 => self.b_reg *= val,
                    0x43 => self.c_reg *= val,
                    0x44 => self.d_reg *= val,
                    else => {},
                }
            },
            opcodes.DIV_REG_V => {
                const reg = self.read_word_from_file();
                var val = self.read_word_from_file();
                switch (val) {
                    0xE0AA => val = self.a_reg,
                    0xE0BB => val = self.b_reg,
                    0xE0CC => val = self.c_reg,
                    0xE0DD => val = self.d_reg,
                    else => {},
                }
                switch (reg) {
                    0x41 => self.a_reg /= val,
                    0x42 => self.b_reg /= val,
                    0x43 => self.c_reg /= val,
                    0x44 => self.d_reg /= val,
                    else => {},
                }
            },
            opcodes.JUMP_IFEQ => {
                switch (self.eq_flag) {
                    true => self.memory_ptr = self.read_word_from_file(),
                    false => {},
                }
                self.eq_flag = false;
            },
            opcodes.JUMP_INEQ => {
                switch (self.eq_flag) {
                    false => self.memory_ptr = self.read_word_from_file(),
                    true => {},
                }
                self.eq_flag = false;
            },
            opcodes.BRAN_IFEQ => {
                self.memory.ram[self.stack_ptr] = self.memory_ptr;
                switch (self.eq_flag) {
                    true => {
                        self.memory_ptr = self.read_word_from_file();
                        self.incr_stack_ptr();
                    },
                    false => {},
                }
                self.eq_flag = false;
            },
            opcodes.BRAN_INEQ => {
                self.memory.ram[self.stack_ptr] = self.memory_ptr;
                switch (self.eq_flag) {
                    false => {
                        self.memory_ptr = self.read_word_from_file();
                        self.incr_stack_ptr();
                    },
                    true => {},
                }
                self.eq_flag = false;
            },
            opcodes.COMP_REGS => {
                var val1 = self.read_word_from_file();
                var val2 = self.read_word_from_file();

                switch (val1) {
                    0x41 => val1 = self.a_reg,
                    0x42 => val1 = self.b_reg,
                    0x43 => val1 = self.c_reg,
                    0x44 => val1 = self.d_reg,
                    else => {},
                }

                switch (val2) {
                    0x41 => val2 = self.a_reg,
                    0x42 => val2 = self.b_reg,
                    0x43 => val2 = self.c_reg,
                    0x44 => val2 = self.d_reg,
                    else => {},
                }

                std.log.info("Comparing {} with {}", .{ val1, val2 });
                if (val1 == val2) {
                    self.eq_flag = true;
                }
            },
            opcodes.AWAIT_INP => {
                self.input_flag = true;
            },
            opcodes.NO_OPERAT => {
                std.log.info("Doing nothing.", .{});
            },
            opcodes.HALT_LOOP => {
                std.log.info("Halting execution.", .{});
                //std.process.exit(0);
                self.halt_flag = true;
            },
            else => {
                std.log.info("Invalid OpCode: {X}", .{instruction});
            },
        }
    }
};
