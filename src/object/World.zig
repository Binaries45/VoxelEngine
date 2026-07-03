//! the world in which our entities live, responsible for handling
//! all component & resource related data

const std = @import("std");
const archetype = @import("archetype.zig");
const Archetype = archetype.Archetype;
const ArchetypeVTable = archetype.ArchetypeVTable;
const object = @import("object.zig");
const ObjectId = object.ObjectId;
const typeId = object.typeId;
const TypeIdBitset = object.TypeIdBitset;

const World = @This();

alloc: std.mem.Allocator,
/// the registry of all unique archetype types, containing a mapping of each archetype hash to its index in `archetypes`
registry: Registry = .{},
/// todo : a list of all archetypes in use by the world
archetypes: std.ArrayList(ArchetypeVTable) = .empty,

/// a registry mapping bundle type hashes to archetype storage keys
pub const Registry = struct {
    map: std.AutoArrayHashMapUnmanaged(TypeIdBitset, u16) = .{},
    next: u16 = 0,

    pub fn deinit(r: *Registry, alloc: std.mem.Allocator) void {
        r.map.deinit(alloc);
    }

    pub fn getOrCreate(r: *Registry, alloc: std.mem.Allocator, bits: TypeIdBitset) !u16 {
        if (r.map.get(bits)) |id| return id;

        const key = r.next;
        r.next += 1;

        try r.map.putNoClobber(alloc, bits, key);
        return key;
    }
};

pub fn deinit(self: *World) void {
    for (self.archetypes.items) |a| a.vtable.deinit(a.ptr, self.alloc);
    self.archetypes.deinit(self.alloc);
    self.registry.deinit(self.alloc);
}

/// spawn an entity from the given bundle, returning its ID
pub fn spawn(w: *World, bundle: anytype) !ObjectId {
    const id = typeId(@TypeOf(bundle));
    const key = try w.registry.getOrCreate(w.alloc, id);
    const BT = @TypeOf(bundle);
    const vtable = if (key < w.archetypes.items.len) w.archetypes.items[key] else blk: {
        if (key != w.archetypes.items.len) @panic("invalid key"); // todo : better message

        const new_ptr = try w.alloc.create(Archetype(BT));
        new_ptr.* = .init(try w.registry.getOrCreate(w.alloc, id));
        const vt: ArchetypeVTable = archetype.generateVTable(BT, new_ptr);

        try w.archetypes.append(w.alloc, vt);
        break :blk w.archetypes.items[key];
    };

    const arch: *Archetype(BT) = @ptrCast(@alignCast(vtable.ptr));
    return arch.new(w.alloc, bundle);
}

/// despawn the object corresponding to id
pub fn despawn(w: *World, id: ObjectId) void {
    const arch = w.archetypes.items[id.key];
    arch.vtable.validate(arch.ptr, id);
    arch.vtable.free(arch.ptr, w.alloc, id);
}

/// get the given field of some object
pub fn get(w: *World, comptime T: type, comptime field: std.meta.FieldEnum(T), id: ObjectId) @FieldType(T, @tagName(field)) {
    const arch = w.archetypes.items[id.key];
    arch.vtable.validate(arch.ptr, id);

    if (std.debug.runtime_safety) {
        std.debug.assert(w.registry.map.get(typeId(T)) == id.key);
    }

    var out: @FieldType(T, @tagName(field)) = undefined;
    arch.vtable.get(arch.ptr, id, @intFromEnum(field), @ptrCast(&out));
    return out;
}

/// get the value of the object corresponding to the given id
pub fn getValue(w: *World, comptime T: type, id: ObjectId) T {
    const arch = w.archetypes.items[id.key];
    arch.vtable.validate(arch.ptr, id);

    if (std.debug.runtime_safety) {
        std.debug.assert(w.registry.map.get(typeId(T)) == id.key);
    }

    var out: T = undefined;
    arch.vtable.getValue(arch.ptr, id, &out);
    return out;
}

test "archetype keys" {
    const a = .{
        @as(u8, 42),
        @as(f32, 3.14),
    };

    const b = .{
        @as(f32, 2.718),
        @as(u8, 21),
    };

    const c = .{
        @as([]const u8, "hello"),
        @as(u8, 100),
    };

    const key_a = typeId(@TypeOf(a));
    const key_b = typeId(@TypeOf(b));
    const key_c = typeId(@TypeOf(c));

    try std.testing.expect(key_a == key_b);
    try std.testing.expect(key_a != key_c);
}

test "type registry" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var reg = Registry{};
    defer reg.deinit(alloc);

    const a = .{
        @as(u8, 42),
        @as(f32, 3.14),
    };

    const b = .{
        @as(f32, 2.718),
        @as(u8, 21),
    };

    const c = .{
        @as([]const u8, "hello"),
        @as(u8, 100),
    };

    const hash_a = typeId(@TypeOf(a));
    const hash_b = typeId(@TypeOf(b));
    const hash_c = typeId(@TypeOf(c));

    const key_a = try reg.getOrCreate(alloc, hash_a);
    const key_b = try reg.getOrCreate(alloc, hash_b);
    const key_c = try reg.getOrCreate(alloc, hash_c);

    try std.testing.expect(key_a == key_b);
    try std.testing.expect(key_a != key_c);
}

test "world spawn" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var world: World = .{ .alloc = alloc };
    defer world.deinit();

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    const kira = try world.spawn(Person{
        .name = @as([]const u8, "Kira Yoshikage"),
        .age = @as(u8, 33),
    });

    const koichi = try world.spawn(Person{
        .name = @as([]const u8, "Koichi Hirose"),
        .age = @as(u8, 15),
    });

    try std.testing.expect(kira.key == koichi.key);

    try std.testing.expect(kira.generation == 0);
    try std.testing.expect(koichi.generation == 0);
    try std.testing.expect(kira.index == 0);
    try std.testing.expect(koichi.index == 1);
}

test "world despawn" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var world: World = .{ .alloc = alloc };
    defer world.deinit();

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    const aya = try world.spawn(Person{
        .name = @as([]const u8, "Aya Tsuji"),
        .age = @as(u8, 26),
    });

    try std.testing.expect(aya.generation == 0);
    try std.testing.expect(aya.index == 0);

    world.despawn(aya);

    const yukako = try world.spawn(Person{
        .name = @as([]const u8, "Yukako Yamagishi"),
        .age = @as(u8, 15),
    });

    try std.testing.expect(yukako.generation == 1);
    try std.testing.expect(yukako.index == 0);
}

test "world get" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var world: World = .{ .alloc = alloc };
    defer world.deinit();

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    const yuya = try world.spawn(Person{
        .name = "Yuya Fungami",
        .age = 18,
    });

    const name = world.get(Person, .name, yuya);
    const age = world.get(Person, .age, yuya);

    try std.testing.expect(std.mem.eql(u8, name, "Yuya Fungami"));
    try std.testing.expect(age == 18);
}

test "world getValue" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var world: World = .{ .alloc = alloc };
    defer world.deinit();
    const Person = struct {
        name: []const u8,
        age: u8,
    };

    const tamami = try world.spawn(Person{
        .name = "Tamami Kobayashi",
        .age = 20,
    });

    const val = world.getValue(Person, tamami);

    try std.testing.expect(std.mem.eql(u8, val.name, "Tamami Kobayashi"));
    try std.testing.expect(val.age == 20);
}
