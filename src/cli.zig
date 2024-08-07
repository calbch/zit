const std = @import("std");
const assert = std.debug.assert;

// Store raw arguments passed on the command line.
const CliArgs = union(enum) {
    init: struct {},
    hash: struct { path: []const u8 },
    // cat: struct { hash: []const u8 },
};

// Store validated and desugared command.
pub const Command = union(enum) {
    pub const Init = struct {};
    pub const Hash = struct { path: []const u8 };
    // pub const Cat = struct { hash: []const u8 };

    init: Init,
    hash: Hash,
    // cat: Cat,
};

pub fn fatal(comptime fmt_string: []const u8, args: anytype) noreturn {
    const stderr = std.io.getStdErr().writer();
    stderr.print("error: " ++ fmt_string ++ "\n", args) catch {};
    std.posix.exit(1);
}

pub fn success(comptime fmt_string: []const u8, args: anytype) noreturn {
    const stderr = std.io.getStdOut().writer();
    stderr.print(fmt_string ++ "\n", args) catch {};
    std.posix.exit(1);
}

fn parse_args(args_iterator: *std.process.ArgIterator) CliArgs {
    assert(args_iterator.skip()); // Skip the executable name (which is the first arg).

    const command = args_iterator.next() orelse fatal("command required, expected one of {s}", .{"init"});

    if (std.mem.eql(u8, command, "init")) {
        return @unionInit(CliArgs, "init", .{});
    } else if (std.mem.eql(u8, command, "hash-object")) {
        const path = args_iterator.next() orelse fatal("file path required", .{});

        // Should I check here if the specified path is valid?

        return @unionInit(CliArgs, "hash", .{ .path = path });
    }
    // else if (std.mem.eql(u8, command, "cat-file")) {
    //     // TODO: Parse hash and add during union init.
    //     return @unionInit(CliArgs, "cat", .{});
    // }

    fatal("unknown command: {s}", .{command});
}

pub fn parse(args_iterator: *std.process.ArgIterator) Command {
    const cli_args = parse_args(args_iterator);

    return switch (cli_args) {
        .init => .{ .init = Command.Init{} },
        .hash => .{ .hash = Command.Hash{ .path = cli_args.hash.path } },
    };
}
