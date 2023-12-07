const g = @import("../common.zig");
const http = @import("http.zig");

const printf = g.printf;

pub fn app() !void {
    printf("hello, world\r\n", .{});

    var req = http.Req{};
    try req.setUrl("https://dyama.net");
    const status = http.request(&req);
    printf("status: {}\r\n", .{status});

    while (true) asm volatile ("hlt");
}
