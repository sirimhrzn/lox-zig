pub const UnexpectedChar = struct {
    line: u8,
    message: *const []u8,
};

pub const CleaError = error{ DefaultError, UnexpectedChar, UnterminatedString, ExpectedIntAfterPoint, UnterminatedComment };
