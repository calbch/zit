const std = @import("std");
const sha1 = @import("std").crypto.hash.Sha1;
const zlib = @import("std").compress.zlib;
const testing = std.testing;

const zit_dir: []const u8 = ".zit";
const object_dir: []const u8 = zit_dir ++ "/objects";

const ZitError = error{ ObjectNotFound, InvalidObjectType, IoError };

const ObjectType = enum {
    object,
    tree,
    commit,

    pub fn toString(self: ObjectType) []const u8 {
        return @tagName(self);
    }
};

pub fn store_blob(path: []const u8) ![40]u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Open the file to store as .zit object.
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try get_file_size(file);
    const header = try create_blob_header(allocator, file_size);
    defer allocator.free(header);

    const hash = try calculate_sha1_hex(file, header, file_size);
    const object_path = try create_object_path(allocator, hash);
    defer allocator.free(object_path);

    try write_compressed_blob(file, object_path);
    return hash;
}

fn get_file_size(file: std.fs.File) !u64 {
    const file_stats = try file.stat();
    return file_stats.size;
}

fn create_blob_header(allocator: std.mem.Allocator, file_size: u64) ![]u8 {
    return try std.fmt.allocPrint(allocator, "blob {d}\u{0000}", .{file_size});
}

fn calculate_sha1_hex(file: std.fs.File, header: []const u8, file_size: u64) ![40]u8 {
    var hasher = sha1.init(.{});
    hasher.update(header);
    var buffer: [4096]u8 = undefined;
    var bytes_read: usize = 0;
    while (bytes_read < file_size) {
        const read_size = try file.read(buffer[0..]);
        if (read_size == 0) break;
        hasher.update(buffer[0..read_size]);
        bytes_read += read_size;
    }
    const sha_1 = hasher.finalResult();
    return std.fmt.bytesToHex(sha_1, .lower);
}

pub fn create_object_subdir(hash_hex: [40]u8) [41]u8 {
    var path: [41]u8 = undefined;
    path[2] = '/';
    std.mem.copyForwards(u8, path[0..2], hash_hex[0..2]);
    std.mem.copyForwards(u8, path[3..], hash_hex[2..]);
    return path;
}

fn create_object_path(allocator: std.mem.Allocator, hash_hex: [40]u8) ![]u8 {
    const path = create_object_subdir(hash_hex);
    return try std.fs.path.join(allocator, &[_][]const u8{ object_dir, &path });
}

// Compress and write file to blob object storage.
fn write_compressed_blob(file: std.fs.File, full_path: []const u8) !void {
    const dirname = std.fs.path.dirname(full_path) orelse return error.IoError;
    try std.fs.cwd().makePath(dirname);

    // Create out file for compressed blob.
    const out_file = try std.fs.cwd().createFile(full_path, .{});
    defer out_file.close();

    // Reposition r/w offset
    try file.seekTo(0);
    var buffered_writer = std.io.bufferedWriter(out_file.writer());
    try zlib.compress(file.reader(), buffered_writer.writer(), .{});
    try buffered_writer.flush();
}

// Write the decompressed zit object blob to the supplied writer.
pub fn read_compressed_blob(allocator: std.mem.Allocator, hash: []const u8, writer: anytype) !void {
    if (hash.len != 40) {
        return ZitError.ObjectNotFound;
    }

    var hashArray: [40]u8 = undefined;
    @memcpy(&hashArray, hash);
    const path = try create_object_path(allocator, hashArray);

    const in_file = try std.fs.cwd().openFile(path, .{});
    defer in_file.close();

    var buffered_writer = std.io.bufferedWriter(writer);
    try zlib.decompress(in_file.reader(), buffered_writer.writer());
    try buffered_writer.flush();
}

test create_object_subdir {
    const hash = "d670460b4b4aece5915caf5c68d12f560a9fe3e4";
    const expected = "d6/70460b4b4aece5915caf5c68d12f560a9fe3e4";
    const actual = create_object_subdir(hash.*);

    try testing.expectEqualStrings(expected, &actual);
}

test create_object_path {
    const hash = "d670460b4b4aece5915caf5c68d12f560a9fe3e4";
    const expected = object_dir ++ "/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4";
    const actual = try create_object_path(testing.allocator, hash.*);
    defer testing.allocator.free(actual);

    try testing.expectEqualStrings(expected, actual);
}
