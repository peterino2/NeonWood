const std = @import("std");
const tokenizer = @import("tokenizer.zig");

const TokenStream = tokenizer.TokenStream;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const AstNodeType = enum {
    terminal, // just
};

const AstNode = struct {
    const Self = @This();
    nodeType: AstNodeType,
    children: ArrayListUnmanaged(*AstNode),
    tok: []const u8 = "NonTerminal",

    pub fn newChild(self: *Self, allocator: std.mem.Allocator) !*AstNode {
        var node = try allocator.create(AstNode);

        try self.children.append(node);
        return node;
    }

    pub fn prettyPrint(self: Self, indentLevel: usize) void {
        var i: usize = 0;
        while (i < indentLevel) : (i += 1) {
            std.debug.print("  ", .{});
        }

        std.debug.print("type: {any} tok: {s}", .{ self.nodeType, self.tok });
    }
};

// examples:
//
// g.hello == true
// person.talkedTo = false + true
// person.amountOfMoney = 420.0 + 69420 * 89
// person2.hatesYou = &person1.hatesYou
//
//
// shitty ebnf:
//
// root = expression [; [expression;]+ ]
//
// expression = operation | dereference | value
//              | label | number | boolean | string
//
// operation = ( expression op expression ) | ( unaryop expression )
// op = EQUIV | NOT_EQUIV | GREATER_EQ | LESS_EQ | GREATER | LESS
// unaryop = NOT | AMPERSAND

const CompilerAst = struct {
    ast_generated: bool = false,
    toks: TokenStream,
    root: *AstNode,
    allocator: std.mem.Allocator,

    // offsets
    offset: usize = 0,
    isParsing: bool = false,

    const Self = @This();

    pub fn init(toks: TokenStream, allocator: std.mem.Allocator) !Self {
        var self = Self{
            .toks = toks,
            .root = undefined,
            .allocator = allocator,
        };

        return self;
    }

    pub fn intoAst(self: *Self) !void {
        self.isParsing = true;

        while (self.isParsing and self.offset < self.toks.tokens.items.len) {
            var latestTok = self.toks.tokens.items[self.offset];
            std.debug.print("{d}:{s}\n", .{ self.offset, latestTok });
            self.offset += 1;
        }
        self.isParsing = false;
    }
};

test "compiler-hello-world" {
    const testSource = "g.hello == true";

    // results in ast:
    //
    //  -- expression --
    //  |      \        \
    //  |       \        \
    //  value    equals   value
    //
    //  compiling an expression:
    //
    //  value equals value:
    //      compile into
    //      compare, FactValue, FactValue

    const testSource2 = "g.hello == !true";
    // expression
    // value(g.hello) operand(==)       expression
    //                              operand(!) value(true)

    // expressions are what are compiled ultimately,
    // this second source compiles into
    //
    //      not value
    //      compare stackRef(0) FactRef(hello)
    //
    // ofc this can be easily optimized into:
    //      compare FactBool(False) FactRef(hello)

    _ = testSource2;
    _ = testSource;
    var tokstream = try tokenizer.TokenStream.MakeTokens(testSource, std.testing.allocator);
    defer tokstream.deinit();

    var ast = try CompilerAst.init(tokstream, std.testing.allocator);
    try ast.intoAst();

    tokstream.test_display();
}
