//! an archetype, storing all objects with the same structure:
//!
//! ```
//! const Name = []const u8;
//! // given the above definition of name, the following
//! // two types would be stored under the same archetype
//! const Thing1 = struct {
//!     name: Name
//! };
//!
//! const Thing2 = struct {
//!     name: []const u8
//! };
//! ```
