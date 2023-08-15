const std = @import("std");
const uefi = std.os.uefi;

var con_in: *uefi.protocols.SimpleTextInputProtocol = undefined;
var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

pub fn main() uefi.Status {
    var status: uefi.Status = undefined;

    con_out = uefi.system_table.con_out orelse return .Unsupported;
    status = con_out.clearScreen();
    if (status != .Success) {
        printf("clearScreen() failed\r\n", .{});
        return status;
    }

    printf("hello, world!\r\n", .{});

    while (true) {}

    return status;
}

fn printf(comptime fmt: []const u8, args: anytype) void {
    var buf: [512]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
    for (text) |c| _ = con_out.outputString(&[_:0]u16{ c, 0 });
}
