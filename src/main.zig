const std = @import("std");
const NodePool = std.ArrayList(Trie.Node);
const data = @embedFile("words_alpha.txt");

const Trie = struct {
    pool: NodePool,
    allocator: std.mem.Allocator,

    pub const Node = struct {
        end: bool,
        children: [256]?*Node,
    };

    pub fn init(allocator: std.mem.Allocator) !Trie {
        return Trie{ .allocator = allocator, .pool = try NodePool.initCapacity(allocator, 3494707) };
    }

    pub fn deinit(self: *Trie) void {
        self.pool.deinit();
    }

    pub fn alloc_node(self: *Trie) !*Node {
        const node = Node{ .end = false, .children = [_]?*Node{null} ** 256 };
        try self.pool.append(node);
        return &(self.pool.items[self.pool.items.len - 1]);
    }

    pub fn add(self: *Trie, root: *Node, slice: []const u8) !void {
        if (slice.len == 0) {
            return;
        }

        const index: usize = @intCast(slice[0]);
        if (root.children[index] == null) {
            var node = try self.alloc_node();
            if (slice.len == 1) {
                node.end = true;
            }
            root.children[index] = node;
        }

        try self.add(root.children[index].?, slice[1..]);
    }

    pub fn print_words(self: *Trie, root: *Node, writer: anytype) !void {
        const index: usize = @intFromPtr(root) - @intFromPtr(self.pool.items.ptr);

        var i: usize = 0;
        while (i < root.children.len) : (i += 1) {
            if (root.children[i]) |node| {
                const c_index: usize = @intFromPtr(node) - @intFromPtr(self.pool.items.ptr);
                try writer.print("  Node_{d} [label=\"{c}\"]\n", .{ c_index, @as(u8, @intCast(i)) });
                try writer.print("  Node_{d} -> Node_{d} [label=\"{c}\"]\n", .{ index, c_index, @as(u8, @intCast(i)) });
                if (node.end) {
                    try writer.print("  Node_{d} [label =\"end\"]\n", .{c_index + 1});
                    try writer.print("  Node_{d} -> Node_{d} [label=\"end\"]\n", .{ c_index, c_index + 1 });
                }
                try self.print_words(node, writer);
            }
        }
    }

    pub fn get_sub_tree(self: *Trie, root: *Node, slice: []const u8) *Node {
        var str = slice[0..];
        var node = root;
        while (str.len > 0) {
            const index: usize = @intCast(str[0]);
            if (node.children[index] == null) {
                break;
            }
            node = node.children[index].?;
            str = str[1..];
        }

        _ = self;

        return node;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout = std.io.getStdOut();
    defer stdout.close();

    const writer = stdout.writer();

    var trie = try Trie.init(allocator);
    defer trie.deinit();

    const root = try trie.alloc_node();

    //var file = try std.fs.cwd().openFile("words_alpha.txt", .{});
    //defer file.close();

    //var buf: [200]u8 = undefined;
    //var buff = std.io.bufferedReader(file.reader());
    //const reader = buff.reader();

    var itr = std.mem.splitScalar(u8, data, '\r');
    //var next = try reader.readUntilDelimiterOrEof(&buf, '\r');
    var next = itr.next();
    while (next) |n| {
        try trie.add(root, n[1..]);
        //next = try file.reader().readUntilDelimiterOrEof(&buf, '\r');
        next = itr.next();
    }

    const slice = "help";
    const node = trie.get_sub_tree(root, slice);
    try writer.print("digraph Trie {c}\n", .{123});
    try writer.print("   Node_{d} [label=root]\n", .{@intFromPtr(root) - @intFromPtr(trie.pool.items.ptr)});
    try trie.print_words(node, writer);
    try writer.print("{c}\n", .{125});
}
