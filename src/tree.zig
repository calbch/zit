const std = @import("std");
const objects = @import("objects.zig");

pub const ZitObject = struct {
    const Self = @This();

    pub const Type = enum { blob, tree };

    type: Type,
    name: []const u8,
    hash_hex: [40]u8,

    pub fn init(allocator: *std.mem.Allocator, object_type: Type, name: []const u8, hash_hex: [40]u8) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .type = object_type,
            // This needs to be duped, since it's a slice.
            .name = try allocator.dupe(u8, name),
            // This does not (fixed size array).
            .hash_hex = hash_hex,
        };
        return self;
    }

    pub fn deinit(self: *Self, allocator: *std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.destroy(self);
    }
};

pub const ZiTree = struct {
    const Self = @This();

    allocator: *std.mem.Allocator,
    value: *ZitObject,
    children: std.ArrayList(*ZiTree),

    pub fn init(allocator: *std.mem.Allocator, value: *ZitObject) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .value = value,
            .children = std.ArrayList(*Self).init(allocator.*),
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit();
        self.allocator.destroy(self);
    }

    pub fn add(self: *Self, value: *ZitObject) !void {
        const child = try Self.init(self.allocator, value);
        try self.children.append(child);
    }
};
