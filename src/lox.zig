const std = @import("std");
const err = @import("error.zig");
const scanner = @import("scanner.zig");

pub const Lox = struct {
    allocator: std.mem.Allocator,
    hasError: bool,

    pub fn init(allocator: std.mem.Allocator) Lox {
        return Lox{ .allocator = allocator, .hasError = false };
    }

    pub fn read_from_stdin(self: *Lox) ![]u8 {
        const stdin = std.io.getStdIn().reader();

        while (true) {
            var buffer: [1024]u8 = undefined;
            const read_size = try stdin.read(&buffer);

            for (0..read_size, buffer[0..read_size]) |i, byte| {
                if (byte == '\n') {
                    self.run(buffer[0..i]);
                    self.hasError = false;
                    break;
                }
            }
        }
    }

    pub fn run(_: *Lox, line: []const u8) void {
        std.debug.print("Recieved line to run: {s} \n", .{line});
        var snr = scanner.Scanner.init(line);
        snr.scanTokens() catch |e| {
            std.debug.print("Line: {d}, Pos: {d} Error: {}", .{ snr.line, snr.curPos, e });
        };
    }
};
