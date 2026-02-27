const std = @import("std");

pub const Reader = struct {
    bytes: []u8,
    pos: usize,

    pub fn init(bytes: []u8) Reader {
        return .{ .bytes = bytes, .pos = 0 };
    }

    pub fn at_eof(self: *Reader) bool {
        return self.pos >= self.bytes.len;
    }

    pub fn skip(self: *Reader, n: u32) !void {
        if (self.pos + n > self.bytes.len) return error.OutOfBoundsSkip;
        self.pos += n;
    }

    pub fn readULEB128(self: *Reader) !u32 {
        var result: u32 = 0;
        var shift: u3 = 0;

        // while the higher order bit is not 0
        while (true) {
            if (self.at_eof()) return error.UnexpectedEof;

            const byte: u8 = self.bytes[self.pos];
            self.pos += 1;

            result |= (byte & 0x7F) << shift;
            shift += 7;

            if ((byte & 0x80) == 0)
                return result;
        }
    }

    pub fn readByte(self: *Reader) !u8 {
        if (self.at_eof()) return error.UnexpectedEof;

        const b = self.bytes[self.pos];
        self.pos += 1;
        return b;
    }
};
