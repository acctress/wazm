pub const FuncType = struct {
    params: []const u8,
    results: []const u8,
};

pub const Local = struct {
    count: u32,
    value_type: u8,
};

pub const FuncBody = struct {
    locals: []Local,
    expr: []u8,
};

pub const Module = struct {
    types: []FuncType,
    funcsec: []u32,
    codesec: []FuncBody,
};
