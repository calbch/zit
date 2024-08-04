const objects = @import("objects.zig");
const tree = @import("tree.zig");
const cli = @import("cli.zig");
const std = @import("std");

// Create the .zit folder where all zit objects are stored.
fn init() !void {
    const init_path: []const u8 = ".zit/objects";
    std.fs.cwd().makePath(init_path) catch |err| switch (err) {
        std.posix.MakeDirError.PathAlreadyExists => {
            cli.success("zit repository already initialized", .{});
        },
        else => {
            std.debug.print("Error: {} init path: {s}\n", .{ err, init_path });
            cli.fatal("failed to init zit repository", .{});
        },
    };

    cli.success("zit repository was initialized", .{});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // const root = try tree.ZitObject.init(&allocator, tree.ZitObject.Type.tree, "root", [_]u8{0} ** 40);
    // defer root.deinit(&allocator);
    // const zt = try tree.ZiTree.init(&allocator, root);
    // defer zt.deinit();

    var arg_iterator = try std.process.argsWithAllocator(allocator);
    defer arg_iterator.deinit();

    const command = cli.parse(&arg_iterator);

    switch (command) {
        .init => try init(),
    }
}
