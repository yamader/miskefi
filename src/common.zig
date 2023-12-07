const std = @import("std");
const uefi = @import("uefi.zig");

pub const allocator = uefi.pool_allocator;

pub var bs: *uefi.tables.BootServices = undefined;
pub var con_in: *uefi.protocol.SimpleTextInput = undefined;
pub var con_out: *uefi.protocol.SimpleTextOutput = undefined;
pub var gop: *uefi.protocol.GraphicsOutput = undefined;
pub var dhcp4: *uefi.protocol.Dhcp4 = undefined;
pub var dhcp6: *uefi.protocol.Dhcp6 = undefined;
pub var dhcp4md: uefi.protocol.Dhcp4.ModeData = undefined;
pub var dhcp6md: uefi.protocol.Dhcp6.ModeData = undefined;
pub var http: *uefi.protocol.Http = undefined;

pub fn printf(comptime fmt: []const u8, args: anytype) void {
    var buf: [512]u8 = undefined;
    const text = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
    for (text) |c| _ = con_out.outputString(&[_:0]u16{ c, 0 });
}

pub fn rnd() u64 {
    var res: u64 = undefined;
    _ = bs.getNextMonotonicCount(&res);
    return res;
}

fn err(comptime fmt: []const u8, args: anytype) uefi.Status {
    printf(fmt, args);
    std.time.sleep(5000_000_000);
    return .Aborted;
}

pub fn init() uefi.Status {
    var status: uefi.Status = undefined;

    bs = uefi.system_table.boot_services orelse return .Unsupported;
    con_in = uefi.system_table.con_in orelse return .Unsupported;
    con_out = uefi.system_table.con_out orelse return .Unsupported;
    _ = con_out.clearScreen();

    printf("initializing gop...\r\n", .{});
    status = bs.locateProtocol(&uefi.protocol.GraphicsOutput.guid, null, @ptrCast(&gop));
    if (status != .Success) return err("locateProtocol(gop) failed: {}\r\n", .{status});

    printf("initializing dhcp4...\r\n", .{});
    status = initDhcp4();
    if (status != .Success) return status;

    // printf("initializing dhcp6...\r\n", .{});
    // status = initDhcp6();
    // if (status != .Success) return status;

    printf("initializing http...\r\n", .{});
    status = initHttp();
    if (status != .Success) return status;

    return status;
}

pub fn initDhcp4() uefi.Status {
    // 参考: https://github.com/vmware/esx-boot/blob/master/uefi/efiutils/dhcpv4.c

    const Dhcp4 = uefi.protocol.Dhcp4;
    var status: uefi.Status = undefined;

    var dhcp4sb: *uefi.protocol.Dhcp4ServiceBinding = undefined;
    status = bs.locateProtocol(&uefi.protocol.Dhcp4ServiceBinding.guid, null, @ptrCast(&dhcp4sb));
    if (status != .Success) return err("locateProtocol(dhcp4sb) failed: {}\r\n", .{status});

    // これいる？
    var hn: usize = undefined;
    var hs: [*]uefi.Handle = undefined;
    status = bs.locateHandleBuffer(.ByProtocol, &Dhcp4.guid, null, &hn, &hs);
    if (status != .NotFound) {
        if (status != .Success) return err("locateHandleBuffer(dhcp4) failed: {}\r\n", .{status});
        defer _ = bs.freePool(@ptrCast(hs));
        for (hs[0..hn]) |h| _ = dhcp4sb.destroyChild(h);
    }

    var maybe_dhcp4_handle: ?uefi.Handle = null;
    status = dhcp4sb.createChild(&maybe_dhcp4_handle);
    if (status != .Success) return err("dhcp4sb.createChild() failed: {}\r\n", .{status});
    const dhcp4_handle = maybe_dhcp4_handle orelse return err("dhcp4_handle is null\r\n", .{});

    // dhcp4をスタックに積むとなんか固まる
    status = bs.handleProtocol(dhcp4_handle, &Dhcp4.guid, @ptrCast(&dhcp4));
    if (status != .Success) return err("handleProtocol(dhcp4) failed: {}\r\n", .{status});

    printf("obtaining ip address... ", .{});
    bind: while (true) {
        status = dhcp4.getModeData(&dhcp4md);
        if (status != .Success) return err("dhcp4.getModeData() failed: {}\r\n", .{status});

        switch (dhcp4md.state) {
            .Stopped => {
                const cfg align(8) = std.mem.zeroes([@sizeOf(Dhcp4.ConfigData)]u8); // wtf
                status = dhcp4.configure(@ptrCast(&cfg));
                if (status != .Success) return err("dhcp4.configure() failed: {}\r\n", .{status});
            },
            .Init => {
                status = dhcp4.start(null);
                if (status != .Success) return err("dhcp4.start() failed: {}\r\n", .{status});
            },
            .Bound => {
                break :bind;
            },
            else => {
                _ = bs.stall(100000);
            },
        }
    }
    printf("{}\r\n", .{dhcp4md.client_address});

    return status;
}

pub fn initDhcp6() uefi.Status {
    // 参考: https://github.com/vmware/esx-boot/blob/master/uefi/efiutils/dhcpv4.c

    const Dhcp6 = uefi.protocol.Dhcp6;
    var status: uefi.Status = undefined;

    var dhcp6sb: *uefi.protocol.Dhcp6ServiceBinding = undefined;
    status = bs.locateProtocol(&uefi.protocol.Dhcp6ServiceBinding.guid, null, @ptrCast(&dhcp6sb));
    if (status != .Success) return err("locateProtocol(dhcp6sb) failed: {}\r\n", .{status});

    // これいる？
    var hn: usize = undefined;
    var hs: [*]uefi.Handle = undefined;
    status = bs.locateHandleBuffer(.ByProtocol, &Dhcp6.guid, null, &hn, &hs);
    if (status != .NotFound) {
        if (status != .Success) return err("locateHandleBuffer(dhcp6) failed: {}\r\n", .{status});
        defer _ = bs.freePool(@ptrCast(hs));
        for (hs[0..hn]) |h| _ = dhcp6sb.destroyChild(h);
    }

    var maybe_dhcp6_handle: ?uefi.Handle = null;
    status = dhcp6sb.createChild(&maybe_dhcp6_handle);
    if (status != .Success) return err("dhcp6sb.createChild() failed: {}\r\n", .{status});
    const dhcp6_handle = maybe_dhcp6_handle orelse return err("dhcp6_handle is null\r\n", .{});

    status = bs.handleProtocol(dhcp6_handle, &Dhcp6.guid, @ptrCast(&dhcp6));
    if (status != .Success) return err("handleProtocol(dhcp6) failed: {}\r\n", .{status});

    var cfg_buf align(8) = std.mem.zeroes([@sizeOf(Dhcp6.ConfigData)]u8); // wtf
    const cfg: *Dhcp6.ConfigData = @ptrCast(&cfg_buf);
    cfg.ia_descriptor = .{
        .type = Dhcp6.Ia.type_na,
        .ia_id = @truncate(rnd()),
    };

    status = dhcp6.configure(cfg);
    if (status != .Success) return err("dhcp6.configure() failed: {}\r\n", .{status});

    printf("obtaining ip address... ", .{});
    bind: while (true) {
        var cd: Dhcp6.ConfigData = undefined;
        status = dhcp6.getModeData(&dhcp6md, &cd);
        if (status != .Success) return err("dhcp6.getModeData() failed: {}\r\n", .{status});

        switch (dhcp6md.ia.state) {
            .Init => {
                status = dhcp6.start();
                if (status != .Success) return err("dhcp6.start() failed: {}\r\n", .{status});
            },
            .Bound => {
                break :bind;
            },
            else => {
                _ = bs.stall(100000);
            },
        }
    }
    printf("{}\r\n", .{dhcp6md.ia.ia_address[0]});

    return status;
}

pub fn initHttp() uefi.Status {
    // 参考: https://github.com/vmware/esx-boot/blob/master/uefi/efiutils/httpfile.c

    const Http = uefi.protocol.Http;
    var status: uefi.Status = undefined;

    var httpsb: *uefi.protocol.HttpServiceBinding = undefined;
    status = bs.locateProtocol(&uefi.protocol.HttpServiceBinding.guid, null, @ptrCast(&httpsb));
    if (status != .Success) return err("locateProtocol(httpsb) failed: {}\r\n", .{status});

    var maybe_http_handle: ?uefi.Handle = null;
    status = httpsb.createChild(&maybe_http_handle);
    if (status != .Success) return err("httsb.createChild() failed: {}\r\n", .{status});
    const http_handle = maybe_http_handle orelse return err("http_handle is null\r\n", .{});

    status = bs.handleProtocol(http_handle, &Http.guid, @ptrCast(&http));
    if (status != .Success) return err("handleProtocol(http) failed: {}\r\n", .{status});

    var ipv4_node = Http.V4AccessPoint{
        .use_default_address = true,
        .local_address = dhcp4md.client_address,
        .local_subnet = dhcp4md.subnet_mask,
        .local_port = @truncate(49160 + (rnd() % 1627) * 10),
    };

    status = http.configure(&.{
        .http_version = ._11,
        .time_out_millisec = 0, // infinite?
        .local_address_is_ipv6 = false,
        .access_point = .{ .ipv4_node = &ipv4_node },
    });
    if (status != .Success) return err("http.configure() failed: {}\r\n", .{status});

    return status;
}
