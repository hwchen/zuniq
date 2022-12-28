// Perf note: removing both filter and stdout stages, timing is the same as runiq doing all stages!
// Does this mean that bufferedReader is especially slow?

const std = @import("std");

const Set = std.HashMapUnmanaged(u64, void, HashContext, 80);
pub const HashContext = struct {
    pub fn hash(self: @This(), k: u64) u64 {
        _ = self;
        return k;
    }
    pub fn eql(self: @This(), a: u64, b: u64) bool {
        _ = self;
        return a == b;
    }
};
const Wyhash = std.hash.Wyhash;

var stdout_mutex = std.Thread.Mutex{};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var filter = Set{};

    var args = try std.process.argsWithAllocator(alloc);
    _ = args.skip();
    const input_path = args.next() orelse return error.MissingInputPath;

    const input_file = blk: {
        if (std.mem.eql(u8, input_path, "-")) {
            break :blk std.io.getStdIn().reader();
        } else {
            break :blk (try std.fs.cwd().openFile(input_path, .{})).reader();
        }
    };
    var br = std.io.bufferedReader(input_file);
    const input = br.reader();

    stdout_mutex.lock();
    defer stdout_mutex.unlock();
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var buf: [1024]u8 = undefined;

    while (try input.readUntilDelimiterOrEof(&buf, '\n')) |line| {
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
