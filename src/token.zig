const std = @import("std");

var reservedKeywords: ?std.StringHashMap(TokenType) = null;

pub const Token = struct {
    token_type: TokenType,
    token_value: ?[]const u8,
    line: u16,
    pos: u16,
    // reservedKeywords: ?std.StringHashMap(TokenType),

    // pub fn init() Token {
    //     return
    // }
    pub fn isIdentReserved(ident: []const u8) !bool {
        if (reservedKeywords == null or reservedKeywords.?.capacity() == 0) {
            try load_reservedKeywords();
        }
        // const tokenType = try reservedKeywords.
        if (reservedKeywords) |k| {
            return k.get(ident) != null;
        }
        return false;
    }

    pub fn getReservedIdent(ident: []const u8) TokenType {
        return reservedKeywords.?.get(ident).?;
    }

    fn load_reservedKeywords() !void {
        var allocator = std.heap.GeneralPurposeAllocator(.{}){};

        var map = std.StringHashMap(TokenType).init(allocator.allocator());
        try map.put("and", TokenType.AND);
        try map.put("class", TokenType.CLASS);
        try map.put("else", TokenType.ELSE);
        try map.put("false", TokenType.FALSE);
        try map.put("fun", TokenType.FUN);
        try map.put("for", TokenType.FOR);
        try map.put("if", TokenType.IF);
        try map.put("nil", TokenType.NIL);
        try map.put("or", TokenType.OR);
        try map.put("print", TokenType.PRINT);
        try map.put("return", TokenType.RETURN);
        try map.put("super", TokenType.SUPER);
        try map.put("this", TokenType.THIS);
        try map.put("true", TokenType.TRUE);
        try map.put("var", TokenType.VAR);
        try map.put("while", TokenType.WHILE);

        reservedKeywords = map;
    }
};
pub const TokenType = enum {
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,
};
