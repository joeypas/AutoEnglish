const std = @import("std");
const Trie = @import("trie.zig").Trie;
const data = @import("trie.zig").data;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout = std.io.getStdOut();
    var stdin = std.io.getStdIn();
    defer stdin.close();
    defer stdout.close();

    const writer = stdout.writer();
    const reader = stdin.reader();
    var trie = try Trie.init(allocator);
    defer trie.deinit();

    const root = try trie.alloc_node();

    // Read wordlist and create trie
    var itr = std.mem.splitScalar(u8, data, '\r');
    var next = itr.next();
    while (next) |n| {
        try trie.add(root, n[1..]);
        //next = try file.reader().readUntilDelimiterOrEof(&buf, '\r');
        next = itr.next();
    }

    // Event Loop
    while (true) {
        try writer.print("Enter prefix: ", .{});

        const slice = try reader.readUntilDelimiterAlloc(
            allocator,
            '\n',
            20,
        );
        defer allocator.free(slice);

        // If nothing is entered exit
        if (slice.len == 0) {
            break;
        }

        const node = trie.get_sub_tree(root, slice);

        // Buffer that writer !!
        var words = std.ArrayList(u8).init(allocator);
        var temp = std.ArrayList(u8).init(allocator);
        defer temp.deinit();
        defer words.deinit();

        try trie.get_autocompletion(node, words.writer(), &temp);
        try writer.print("{s}", .{words.items});
        try writer.print("\n", .{});
    }
}
