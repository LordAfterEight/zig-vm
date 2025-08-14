// NOTE: CPU OPCODES

// --- OpCodes: NoOp
/// OpCode: No operation. Simply doesn't do anything except increasing the instruction pointer
pub const NO_OPERAT: u16 = 0x00A0;

// --- OpCodes: Halt
/// OpCode: Sets the CPU's halt_flag to true
pub const HALT_LOOP: u16 = 0x00AF;

// --- OpCodes: Load into Register ---
/// OpCode: Loads the following value into A register
pub const LOAD_AREG: u16 = 0x00A1;
/// OpCode: Loads the following value into X register
pub const LOAD_BREG: u16 = 0x00A2;
/// OpCode: Loads the following value into Y register
pub const LOAD_CREG: u16 = 0x00A3;
/// OpCode: Loads the following value into G register
pub const LOAD_DREG: u16 = 0x00A4;

// --- OpCodes: Load into Register ---
/// OpCode: Stores the A register's value to the following address
pub const STOR_AREG: u16 = 0x00B1;
/// OpCode: Stores the X register's value to the following address
pub const STOR_BREG: u16 = 0x00B2;
/// OpCode: Stores the Y register's value to the following address
pub const STOR_CREG: u16 = 0x00B3;
/// OpCode: Stores the G register's value to the following address
pub const STOR_DREG: u16 = 0x00B4;

// --- OpCodes: Jump to Subroutine ---
/// OpCode: Sets the instruction pointer to the value of the following address, jumping there.
///         This also pushes the previous value to the stack, allowing to return to where the
///         program came from using the ```RET_TO_OR``` (Return To Origin) OpCode.
pub const JMP_TO_SR: u16 = 0x00C1;

// --- OpCodes: Jump to following Address ---
/// OpCode: Sets the instruction pointer to the value of the following address, jumping there.
pub const JMP_TO_AD: u16 = 0x00C0;

// --- OpCodes: Return from Subroutine / Return to Origin ---
/// OpCode: Fetches the value previously pushed to the stack and sets the instruction pointer to
///         it, returning to where the program came from.
pub const RET_TO_OR: u16 = 0x00D1;

// --- OpCodes: Compare two registers ---
/// OpCodes: Compares two registers and sets the eq_flag accordingly.
pub const COMP_REGS: u16 = 0x00D6;

// --- OpCodes: Jump if equal ---
/// OpCodes: Jumps to the following address if the eq_flag is true
pub const JUMP_IFEQ: u16 = 0x00C2;

// --- OpCodes: Jump if not equal ---
/// OpCodes: Jumps to the following address if the eq_flag is false
pub const JUMP_INEQ: u16 = 0x00C3;

// --- OpCodes: Increment register value ---
/// OpCodes: Increases the value in the register specified in the following address by the value
///          specified in the second address after the opcode
pub const INC_REG_V: u16 = 0x00D2;

// --- OpCodes: Decrement register value ---
/// OpCodes: Decreases the value in the register specified in the following address by the value
///          specified in the second address after the opcode
pub const DEC_REG_V: u16 = 0x00D3;

// --- OpCodes: Multiply register value ---
/// OpCodes: Multiplies the value in the register specified in the following address by the value
///          specified in the second address after the opcode
pub const MUL_REG_V: u16 = 0x00D4;

// --- OpCodes: Divide register value ---
/// OpCodes: Divides the value in the register specified in the following address by the value
///          specified in the second address after the opcode
pub const DIV_REG_V: u16 = 0x00D5;
