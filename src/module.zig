pub const FuncType = struct {
    params: []const u8,
    results: []const u8,
};

pub const Module = struct {
    types: []FuncType,
};
