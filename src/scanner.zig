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
        while (self.curPos < self.source.len) {
            self.scanToken() catch |e| {
                std.debug.print("Line: {d}, Pos: {d} Error: {} \n", .{ self.line, self.curPos, e });
            };
        }
    }

    fn scanToken(self: *Scanner) !void {
        const char = self.getCurrentChar();
        self.startPos = self.curPos;
        defer self.advance();

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
            ';' => try self.add_token(token.TokenType.SEMICOLON, ";"),
            '!' => try self.addTokenIfNextIs('=', token.TokenType.BANG_EQUAL, token.TokenType.BANG),
            '=' => try self.addTokenIfNextIs('=', token.TokenType.EQUAL_EQUAL, token.TokenType.EQUAL),
            '>' => try self.addTokenIfNextIs('=', token.TokenType.GREATER_EQUAL, token.TokenType.GREATER),
            '<' => try self.addTokenIfNextIs('=', token.TokenType.LESS_EQUAL, token.TokenType.LESS),
            '/' => {
                if (self.peek() == '/') {
                    self.eat_comments();
                } else if (self.peek() == '*') {
                    while (!self.isAtEnd()) {
                        if (self.source[self.curPos] == '*' and self.peek() == '/') {
                            self.advance();
                            return;
                        }
                        if (self.source[self.curPos] == '\n') {
                            self.line += 1;
                        }
                        self.advance();
                    }
                    return err.CleaError.UnterminatedComment;
                } else {
                    try self.add_token(token.TokenType.SLASH, null);
                }
            },
            '"' => try self.handleDQuote(),
            else => {
                if (isDigit(char)) {
                    try self.handleDigit();
                    return;
                }
                if (isAlpha(char)) {
                    try self.handleIdent();
                    return;
                }
                return err.CleaError.UnexpectedChar;
            },
        };
    }

    fn handleIdent(self: *Scanner) !void {
        while (isAlphaNumeric(self.peek())) {
            self.advance();
        }
        const ident = self.source[self.startPos .. self.curPos + 1];
        const isReserved = try token.Token.isIdentReserved(ident);
        if (isReserved) {
            try self.add_token(token.Token.getReservedIdent(ident), ident);
        } else {
            try self.add_token(token.TokenType.IDENTIFIER, ident);
        }
    }

    fn isAlpha(char: ?u8) bool {
        if (char == null) {
            return false;
        }
        return (char.? >= 'a' and char.? <= 'z') or (char.? >= 'A' and char.? <= 'Z') or char.? == '_';
    }

    fn isAlphaNumeric(char: ?u8) bool {
        return isAlpha(char) or isDigit(char);
    }

    fn handleDigit(self: *Scanner) !void {
        while (isDigit(self.peek())) {
            self.advance();
            if (self.peek() == '.' and !isDigit(self.peekNext())) {
                return err.CleaError.ExpectedIntAfterPoint;
            }
            if (self.peek() == '.') {
                self.advance();
            }
        }
        self.advance();
        try self.add_token(token.TokenType.NUMBER, self.source[self.startPos..self.curPos]);
    }
    fn peekNext(self: *Scanner) ?u8 {
        if (self.curPos + 2 < self.source.len) {
            return self.source[self.curPos + 2];
        }
        return null;
    }

    fn isDigit(char: ?u8) bool {
        if (char == null) {
            return false;
        }
        return char.? >= '0' and char.? <= '9';
    }

    fn handleDQuote(self: *Scanner) !void {
        while (self.peek() != '"' and self.peek() != null and !self.isAtEnd()) {
            if (self.source[self.curPos] == '\n') {
                self.line += 1;
            }
            self.advance();
        }
        if (self.peek() != '"' and self.isAtEnd()) {
            return err.CleaError.UnterminatedString;
        }
        if (self.peek() == '"') {
            self.advance();
            try self.add_token(token.TokenType.STRING, self.source[self.startPos + 1 .. self.curPos]);
        }
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

test "parse number " {
    const source = [_]u8{ '0', '5', '9' };
    var snr = Scanner.init(source[0..source.len]);
    _ = try snr.scanToken();
    const numberToken = snr.tokens.pop();
    try std.testing.expect(token.TokenType.NUMBER == numberToken.token_type);
    try std.testing.expect(std.mem.eql(u8, numberToken.token_value.?, "059"));
}

test "should throw ExpectedIntAfterPoint" {
    const source = [_]u8{ '0', '5', '9', '.' };
    var snr = Scanner.init(source[0..source.len]);
    try std.testing.expectError(err.CleaError.ExpectedIntAfterPoint, snr.scanToken());
}
test "parse float" {
    const source = [_]u8{ '0', '5', '9', '.', '9', '5', '0' };
    var snr = Scanner.init(source[0..source.len]);
    _ = try snr.scanToken();
    const numberToken = snr.tokens.pop();

    try std.testing.expect(token.TokenType.NUMBER == numberToken.token_type);
    try std.testing.expect(std.mem.eql(u8, numberToken.token_value.?, "059.950"));
}

test "should identify reserved keywords and user identifiers" {
    const source = "var name = \"tanisha\"; ";

    var snr = Scanner.init(source[0..source.len]);
    _ = try snr.scanTokens();

    const semiColonToken = snr.tokens.pop();
    try std.testing.expect(semiColonToken.token_type == token.TokenType.SEMICOLON);
    try std.testing.expect(std.mem.eql(u8, semiColonToken.token_value.?, ";"));

    const stringToken = snr.tokens.pop();
    try std.testing.expect(stringToken.token_type == token.TokenType.STRING);
    try std.testing.expect(std.mem.eql(u8, stringToken.token_value.?, "tanisha"));

    const equalToken = snr.tokens.pop();
    try std.testing.expect(equalToken.token_type == token.TokenType.EQUAL);

    const identifierToken = snr.tokens.pop();
    try std.testing.expect(identifierToken.token_type == token.TokenType.IDENTIFIER);
    try std.testing.expect(std.mem.eql(u8, identifierToken.token_value.?, "name"));

    const varToken = snr.tokens.pop();
    try std.testing.expect(varToken.token_type == token.TokenType.VAR);
    try std.testing.expect(std.mem.eql(u8, varToken.token_value.?, "var"));
}

test "skip c like comments" {
    const source = "/* Testing c like comments */ var";

    var snr = Scanner.init(source[0..source.len]);
    _ = try snr.scanTokens();
    const varToken = snr.tokens.pop();
    try std.testing.expect(varToken.token_type == token.TokenType.VAR);
    try std.testing.expect(snr.tokens.items.len == 0);
}

//XXX assert line count as well
test "detect  UnterminatedComment error on C like comment" {
    const source = "/* Testing c like comments ";

    var snr = Scanner.init(source[0..source.len]);
    try std.testing.expectError(err.CleaError.UnterminatedComment, snr.scanToken());
}

test "detect  UnterminatedComment error on C like comment ending with *" {
    const source = "/* Testing c like comments *";

    var snr = Scanner.init(source[0..source.len]);
    try std.testing.expectError(err.CleaError.UnterminatedComment, snr.scanToken());
}
