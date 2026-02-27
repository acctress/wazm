const std = @import("std");
const decoder = @import("decoder.zig");

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var test_file = try std.fs.cwd().openFile("test.wasm", .{ .mode = .read_only });
    defer test_file.close();

    const test_source: []u8 = try test_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(test_source);

    // var bytes = [_]u8{ 0x00, 0x61, 0x73, 0x6D, 0x00, 0x00, 0x00, 0x00 };
    var dec: decoder.Decoder = .init(allocator, test_source);
    const module = try dec.decode();

    std.debug.print("module has {d} types\n", .{module.types.len});

    for (module.types) |t| {
        std.debug.print("type func has {d} parameter(s)\n", .{t.params.len});
        std.debug.print("type func has {d} result(s)\n", .{t.results.len});
    }

    for (module.funcsec) |v| {
        std.debug.print("func indicie {d}\n", .{v});
    }

    for (module.codesec) |c| {
        std.debug.print("code sec func body has {d} local(s)\n", .{c.locals.len});
        std.debug.print("code sec func body expr size is {d}\n", .{c.expr.len});
    }
}
