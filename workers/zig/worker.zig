const std = @import("std");
const Io = std.Io;

fn isPrime(n: u64) bool {
    if (n < 2) return false;
    var i: u64 = 2;
    while (i * i <= n) : (i += 1) {
        if (n % i == 0) return false;
    }
    return true;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        var stdout_buffer: [256]u8 = undefined;
        var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
        try stdout_writer.interface.writeAll("{\"error\":\"missing limit\"}");
        try stdout_writer.flush();
        return;
    }

    const limit = try std.fmt.parseInt(u64, args[1], 10);
    var count: u64 = 0;
    var last: u64 = 0;
    var value: u64 = 2;
    while (value <= limit) : (value += 1) {
        if (isPrime(value)) {
            count += 1;
            last = value;
        }
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("{{\"limit\":{},\"count\":{},\"lastPrime\":{}}}", .{ limit, count, last });
    try stdout_writer.flush();
}
