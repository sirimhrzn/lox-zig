const std = @import("std");
const Lox = @import("lox.zig").Lox;

const allocator = std.heap.page_allocator;

pub fn main() !void {
    var lox = Lox.init(allocator);
    _ = try lox.read_from_stdin();
}
