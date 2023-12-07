const std = @import("std");
const g = @import("../common.zig");
const uefi = @import("../uefi.zig");

const BS = uefi.tables.BootServices;
const Http = uefi.protocol.Http;

pub const Req = struct {
    const Self = @This();

    method: Http.Method = .Get,
    url: [256:0]u16 = undefined,
    header_count: usize = 0,
    headers: [32]Http.Header = undefined,
    body_length: usize = 0,
    body: ?[*]u8 = null,
    done: bool = false,

    _req: Http.RequestData = undefined,
    _msg: Http.Message = undefined,

    pub fn setUrl(self: *Self, url: []const u8) !void {
        _ = try std.unicode.utf8ToUtf16Le(&self.url, url);
    }

    pub fn msg(self: *Self) *Http.Message {
        self._req = .{ .method = self.method, .url = &self.url };
        self._msg = .{
            .data = .{ .request = &self._req },
            .header_count = self.header_count,
            .headers = &self.headers,
            .body_length = self.body_length,
            .body = self.body,
        };
        return &self._msg;
    }
};

pub const Res = struct {
    status_code: Http.StatusCode,
    header_count: usize,
    headers: [*]Http.Header,
    body_length: usize,
    body: ?[*]u8,
};

pub fn request(req: *Req) uefi.Status {
    var status: uefi.Status = undefined;

    var e: uefi.Event = undefined;
    status = g.bs.createEvent(
        BS.event_notify_signal,
        BS.tpl_callback,
        notifyHandler,
        req,
        &e,
    );
    if (status != .Success) return status;
    defer _ = g.bs.closeEvent(e);

    const token = Http.Token{
        .event = e,
        .status = .Success,
        .message = req.msg(),
    };
    status = g.http.request(&token);
    if (status != .Success) return status;

    // while (!req.done) {}

    return status;
}

fn notifyHandler(_: uefi.Event, ctx: ?*anyopaque) callconv(uefi.cc) void {
    const req: *Req = @alignCast(@ptrCast(ctx orelse return));
    g.printf("notify: {?}\r\n", .{req});
}
