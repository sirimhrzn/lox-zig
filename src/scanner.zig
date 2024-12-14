const std = @import("std");
const token = @import("token.zig");
const err = @import("error.zig");

const allocator = std.heap.page_allocator;

pub const Scanner = struct {
    source: []const u8,
    line: u8,
    curPos: u16,
    startPos: u16,
    tokens: std.ArrayList(token.Token),

    pub fn init(source: []const u8) Scanner {
        return Scanner{ .source = source, .line = 1, .curPos = 0, .startPos = 0, .tokens = std.ArrayList(token.Token).init(allocator) };
    }

    pub fn scanTokens(self: *Scanner) !void {
        std.debug.print("scanning tokens \n", .{});
        // var i: u16 = 0;
        while (self.curPos < self.source.len) {
            self.scanToken() catch |e| {
                std.debug.print("Line: {d}, Pos: {d} Error: {} \n", .{ self.line, self.curPos, e });
            };
        }
    }

    fn scanToken(self: *Scanner) !void {
        const char = self.getCurrentChar();
        defer self.advance();

        std.debug.print("Recieved char: %{c}% at pos {d} \n", .{ char, self.curPos });

        return switch (char) {
            ' ' => {},
            '(' => try self.add_token(token.TokenType.LEFT_PAREN, null),
            ')' => try self.add_token(token.TokenType.RIGHT_PAREN, null),
            '{' => try self.add_token(token.TokenType.LEFT_BRACE, null),
            '}' => try self.add_token(token.TokenType.RIGHT_BRACE, null),
            ',' => try self.add_token(token.TokenType.COMMA, null),
            '.' => try self.add_token(token.TokenType.DOT, null),
            '-' => try self.add_token(token.TokenType.MINUS, null),
            '+' => try self.add_token(token.TokenType.PLUS, null),
            '*' => try self.add_token(token.TokenType.STAR, null),
            ';' => try self.add_token(token.TokenType.SEMICOLON, null),
            '!' => try self.addTokenIfNextIs('=', token.TokenType.BANG_EQUAL, token.TokenType.BANG),
            '=' => try self.addTokenIfNextIs('=', token.TokenType.EQUAL_EQUAL, token.TokenType.EQUAL),
            '>' => try self.addTokenIfNextIs('=', token.TokenType.GREATER_EQUAL, token.TokenType.GREATER),
            '<' => try self.addTokenIfNextIs('=', token.TokenType.LESS_EQUAL, token.TokenType.LESS),
            '/' => {
                if (self.peek() == '/') {
                    self.eat_comments();
                } else {
                    try self.add_token(token.TokenType.SLASH, null);
                }
            },
            '"' => {
                self.startPos = self.curPos;
                while (self.peek() != '"' and self.peek() != null and !self.isAtEnd()) {
                    self.advance();
                }
                if (self.peek() != '"' and self.isAtEnd()) {
                    return err.CleaError.UnterminatedString;
                }
                if (self.peek() == '"') {
                    self.advance();
                    try self.add_token(token.TokenType.STRING, self.source[self.startPos + 1 .. self.curPos]);
                }
            },
            else => return err.CleaError.UnexpectedChar,
        };
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.source.len - 1 == self.curPos;
    }
    fn eat_comments(self: *Scanner) void {
        while (self.peek() != '\n' and self.peek() != null) {
            self.advance();
        }
    }

    fn addTokenIfNextIs(self: *Scanner, expected: u8, ifTrue: token.TokenType, ifFalse: token.TokenType) !void {
        if (self.isNext(expected)) {
            try self.add_token(ifTrue, null);
        } else {
            try self.add_token(ifFalse, null);
        }
    }

    fn isNext(self: *Scanner, expected: u8) bool {
        return self.peek() == expected;
    }

    fn peek(self: *Scanner) ?u8 {
        if (self.curPos + 1 < self.source.len) {
            return self.source[self.curPos + 1];
        }
        return null;
    }

    fn add_token(self: *Scanner, tokenType: token.TokenType, tokenValue: ?[]const u8) !void {
        try self.tokens.append(token.Token{ .line = self.line, .pos = self.curPos, .token_type = tokenType, .token_value = tokenValue });
    }

    fn getCurrentChar(self: *Scanner) u8 {
        const char = self.source[self.curPos];
        return char;
    }

    fn advance(self: *Scanner) void {
        self.curPos += 1;
    }
};

test "match peeked character" {
    const source = [_]u8{ '!', '(' };
    var snr = Scanner.init(source[0..source.len]);
    const char = snr.peek();
    try std.testing.expect(char == '(');
}

test "eat all comments" {
    const source = [_]u8{ '/', '/', 'c', 'h', '\n' };
    var snr = Scanner.init(source[0..source.len]);
    snr.eat_comments();
    try std.testing.expect(snr.source[snr.curPos] == 'h');
}

test "parse string into string token" {
    const source = [_]u8{ '"', 's', 't', 'r', 'i', 'n', 'g', '"' };
    var snr = Scanner.init(source[0..source.len]);
    try snr.scanToken();
    const stringToken = snr.tokens.pop();
    try std.testing.expect(stringToken.token_type == token.TokenType.STRING);
    try std.testing.expect(std.mem.eql(u8, stringToken.token_value.?, "string"));
}

test "should throw UnterminatedString error" {
    const source = [_]u8{ '"', 's', 't', 'r', 'i', 'n', 'g' };
    var snr = Scanner.init(source[0..source.len]);
    try std.testing.expectError(err.CleaError.UnterminatedString, snr.scanToken());
}
