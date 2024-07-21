const std = @import("std");
const sha1 = @import("std").crypto.hash.Sha1;

const zit_path: []const u8 = ".zit";
const object_path: []const u8 = zit_path + "/objects/";

const ZitError = error{ ObjectNotFound, InvalidObjectType, IoError };

const ObjectType = enum {
    object,
    tree,
    commit,

    pub fn toString(self: ObjectType) []const u8 {
        return switch (self) {
            .object => "object",
            .tree => "tree",
            .commit => "commit",
        };
    }
};

pub fn store_blob(path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Open the file
    const content = std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(usize)) catch {
        return ZitError.IoError;
    };
    defer allocator.free(content);

    // Create the header according to the git docs
    const header = try std.fmt.allocPrint(allocator, "blob {d}\u{0000}", .{content.len});
    defer allocator.free(header);

    const store = try std.mem.concat(allocator, u8, &[_][]const u8{ header, content });
    defer allocator.free(store);

    const hash = try create_sha1_hash(allocator, store);
    defer allocator.free(hash);

    const dir_name = hash[0..2];
    const file_name = hash[2..hash.len];

    std.debug.print("header: {d}\ncontent: {d}\nheader: {d}\n", .{ header.len, content.len, store.len });
    std.debug.print("file name: {s}/{s}", .{ dir_name, file_name });
}

fn create_sha1_hash(data: []const u8) [40]u8 {
    var sha_1: [sha1.digest_length]u8 = undefined;
    sha1.hash(data, &sha_1, .{});

    return std.fmt.bytesToHex(sha_1, .lower);
}

fn create_object_path(hash: [40]u8) [41]u8 {
    var path: [41]u8 = undefined;
    path[2] = '/';
    std.mem.copyForwards(u8, path[0..2], hash[0..2]);
    std.mem.copyForwards(u8, path[3..], hash[2..]);
    return path;
}

test "object path test" {
    const test_string = "foobarbaz";
    const expected_path = "5f/5513f8822fdbe5145af33b64d8d970dcf95c6e";

    const hash = create_sha1_hash(test_string);
    const path = create_object_path(hash);

    try std.testing.expectEqualStrings(expected_path, &path);
}

pub fn create_blob_header() []u8 {}

pub fn main() !void {
    try store_blob("build.zig");
}
