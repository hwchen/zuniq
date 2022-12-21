const std = @import("std");
const Set = std.AutoHashMapUnmanaged(u64, void);
const Wyhash = std.hash.Wyhash;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var filter = Set{};

    const stdin_file = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_file);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var buf: [1024 * 8]u8 = undefined;

    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const key = hash(line);
        if (try filter.fetchPut(alloc, key, {})) |_| {
            continue;
        } else {
            try stdout.print("{s}\n", .{line});
        }

        // debug
        //std.debug.print("line: {s}\n", .{line});
        //var key_it = filter.keyIterator();
        //while (key_it.next()) |key| {
        //    std.debug.print("  key: {s}\n", .{key.*});
        //}
    }

    try bw.flush(); // don't forget to flush!
}

fn hash(input: []const u8) u64 {
    return Wyhash.hash(42, input);
}
