const std = @import("std");
const leb128 = @import("leb128.zig");
const module = @import("module.zig");

pub const Decoder = struct {
    allocator: std.mem.Allocator,
    reader: leb128.Reader,

    pub fn init(allocator: std.mem.Allocator, bytes: []u8) Decoder {
        return .{
            .allocator = allocator,
            .reader = .init(bytes),
        };
    }

    pub fn decode(self: *Decoder) !module.Module {
        try self.readMagicHeader();

        var mod: module.Module = .{
            .types = try self.allocator.alloc(module.FuncType, 12),
            .funcsec = undefined,
            .codesec = undefined,
        };

        var i: u32 = 0;
        while (!self.reader.at_eof()) : (i += 1) {
            const section_id = try self.reader.readByte();
            const section_len = try self.reader.readULEB128(); // section length

            if (section_id == 0x01) {
                mod.types = try self.parseTypeSection();
            } else if (section_id == 0x03) {
                mod.funcsec = try self.parseFunctionSection();
            } else if (section_id == 0x0A) {
                mod.codesec = try self.parseCodeSection();
            } else {
                try self.reader.skip(section_len);
            }
        }

        return mod;
    }

    fn readMagicHeader(self: *Decoder) !void {
        var i: u8 = 0;
        while (i <= 7) : (i += 1) {
            const byte = try self.reader.readByte();

            if ((i == 0 and byte != 0x00) or
                (i == 1 and byte != 0x61) or
                (i == 2 and byte != 0x73) or
                (i == 3 and byte != 0x6D))
                return error.InvalidMagic;

            if ((i == 4 and byte != 0x01) or
                (i == 5 and byte != 0x00) or
                (i == 6 and byte != 0x00) or
                (i == 7 and byte != 0x00))
                return error.InvalidVersion;
        }
    }

    fn parseTypeSection(self: *Decoder) ![]module.FuncType {
        const num_of_types = try self.reader.readULEB128(); // how many type sections to parse

        var section = try self.allocator.alloc(module.FuncType, num_of_types);

        var i: u32 = 0;
        while (i < num_of_types) : (i += 1) {
            const marker = try self.reader.readByte();

            const type_def: error{UnsupportedType}!module.FuncType = switch (marker) {
                0x60 => try self.parseFunctionType(),
                else => error.UnsupportedType,
            };

            section[i] = (try type_def);
        }

        return section;
    }

    fn parseFunctionType(self: *Decoder) !module.FuncType {
        const param_count = try self.reader.readULEB128();
        const params = try self.allocator.alloc(u8, param_count);

        var j: u32 = 0;
        while (j < param_count) : (j += 1) {
            params[j] = try self.reader.readByte();
        }

        const result_count = try self.reader.readULEB128();
        const results = try self.allocator.alloc(u8, result_count);

        var k: u32 = 0;
        while (k < result_count) : (k += 1) {
            results[k] = try self.reader.readByte();
        }

        return .{ .params = params, .results = results };
    }

    fn parseFunctionSection(self: *Decoder) ![]u32 {
        const indice_count = try self.reader.readULEB128();
        var indices = try self.allocator.alloc(u32, indice_count);

        var i: u32 = 0;
        while (i < indice_count) : (i += 1) {
            indices[i] = try self.reader.readULEB128();
        }

        return indices;
    }

    fn parseCodeSection(self: *Decoder) ![]module.FuncBody {
        const entries = try self.reader.readULEB128();

        var bodies = try self.allocator.alloc(module.FuncBody, entries);

        for (0..entries) |i| {
            // entry length, ignorte for now
            _ = try self.reader.readULEB128();

            var body: module.FuncBody = .{
                .locals = undefined,
                .expr = undefined,
            };

            const local_decl_count = try self.reader.readULEB128();

            body.locals = try self.allocator.alloc(module.Local, local_decl_count);

            for (0..local_decl_count) |j| {
                const count = try self.reader.readULEB128();
                const value_type = try self.reader.readByte();

                body.locals[j] = module.Local{
                    .count = count,
                    .value_type = value_type,
                };
            }

            var bytes = std.array_list.Managed(u8).init(self.allocator);
            while (true) {
                const byte = try self.reader.readByte();
                if (byte == 0x0B) break;
                try bytes.append(byte);
            }

            body.expr = try bytes.toOwnedSlice();

            bodies[i] = body;
        }

        return bodies;
    }
};
