// note : the goal with archetype storage and the object function is to store
//        all similar types in an archetype table as a struct of arrays,
//        we're gonna have to do some wacky comptime stuff to construct this
//        storage and create these types, also archetypes will have to be
//        type-erased so that we can then store all archetypes in our world

const std = @import("std");
pub const Archetype = @import("archetype.zig");
pub const World = @import("World.zig");

/// return a unique usize for the given type
// note : when id was const, optimizations would cause type ids to combine,
// and when called from the key function would generate this assembly:
// ```
// example.key_test:
//        push    rbp
//        mov     rbp, rsp
//        xor     eax, eax
//        pop     rbp
//        ret
// ```
// the `xor eax, eax` meant that the function was just returning 0,
// but making id into a var caused the assembly to become:
// ```
// example.key_test:
//        push    rbp
//        mov     rbp, rsp
//        mov     ecx, offset example.typeId__anon_575__struct_593.id
//        mov     eax, offset example.typeId__anon_563__struct_586.id
//        xor     rax, rcx
//        pop     rbp
//        ret
// ```
// notice how the ids are now stored and their offsets are loaded and used in the xor.
//
// the below approach using the hash of the type name worked kinda of well,
// as its values could be optimized into compile time constants, but type names were too short,
// causing u8 and f32 to actually have a hash collision lol,
// maybe in the future we revisit this with a custom hash function built to
// better support small strings, but i doubt it
//
// pub fn typeId(comptime T: type) usize {
//     return std.hash_map.hashString(@typeName(T));
// }

// This function is stupid, but it works
pub fn typeId(comptime T: type) usize {
    return @intFromPtr(&struct {
        const t: type = T;
        var id: u8 = 0;
    }.id);
}


test "type ids" {
    try std.testing.expect(typeId(u32) == typeId(u32));
    try std.testing.expect(typeId(u32) != typeId(f32));

    // struct tests
    const Dummy = struct { x: u32 };
    try std.testing.expect(typeId(u32) != typeId(struct{ x: u32 }));
    try std.testing.expect(typeId(struct{ x: u32 }) != typeId(struct{ x: u32 }));
    try std.testing.expect(typeId(Dummy) != typeId(struct{ x: u32 }));
    try std.testing.expect(typeId(Dummy) == typeId(Dummy));

    // ZST tests
    try std.testing.expect(typeId(void) == typeId(void));
    try std.testing.expect(typeId(void) != typeId(struct{}));

    // alias tests
    const Name = []const u8;
    try std.testing.expect(typeId(Name) == typeId([]const u8));

    // generic type tests
    try std.testing.expect(typeId(std.ArrayList(u32)) == typeId(std.ArrayList(u32)));
}

test "object" {
    _ = Archetype;
    _ = World;
}

