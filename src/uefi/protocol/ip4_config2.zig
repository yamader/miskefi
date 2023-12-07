const uefi = @import("std").os.uefi;

const Ip4 = @import("ip4.zig").Ip4;

pub const Ip4Config2 = extern struct {
    const Self = @This();

    _set_data: *const fn (*const Ip4Config2, DataType, usize, *anyopaque) callconv(uefi.cc) uefi.Status,
    _get_data: *const fn (*const Ip4Config2, DataType, *usize, ?*anyopaque) callconv(uefi.cc) uefi.Status,
    _register_data_notify: *const fn (*const Ip4Config2, DataType, uefi.Event) callconv(uefi.cc) uefi.Status,
    _unregister_data_notify: *const fn (*const Ip4Config2, DataType, uefi.Event) callconv(uefi.cc) uefi.Status,

    pub fn setData(self: *const Self, data_type: DataType, data_size: usize, data: *anyopaque) uefi.Status {
        return self._set_data(self, data_type, data_size, data);
    }

    pub fn getData(self: *const Self, data_type: DataType, data_size: *usize, data: ?*anyopaque) uefi.Status {
        return self._get_data(self, data_type, data_size, data);
    }

    pub fn registerDataNotify(self: *const Self, data_type: DataType, event: uefi.Event) uefi.Status {
        return self._register_data_notify(self, data_type, event);
    }

    pub fn unregisterDataNotify(self: *const Self, data_type: DataType, event: uefi.Event) uefi.Status {
        return self._unregister_data_notify(self, data_type, event);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x5b446ed1,
        .time_mid = 0xe30b,
        .time_high_and_version = 0x4faa,
        .clock_seq_high_and_reserved = 0x87,
        .clock_seq_low = 0x1a,
        .node = [6]u8{ 0x36, 0x54, 0xec, 0xa3, 0x60, 0x80 },
    };

    pub const DataType = enum(u32) {
        InterfaceInfo,
        Policy,
        ManualAddress,
        Gateway,
        DnsServer,
        Maximum,
    };

    pub const InterfaceInfoNameSize = 32;
    pub const InterfaceInfo = extern struct {
        name: [InterfaceInfoNameSize:0]u16,
        if_type: u8,
        hw_address_size: u32,
        hw_address: uefi.MacAddress,
        station_address: uefi.Ipv4Address,
        subnet_mask: uefi.Ipv4Address,
        route_table_size: u32,
        route_table: ?*Ip4.RouteTable,
    };

    pub const Policy = enum(u32) {
        Static,
        Dhcp,
        Max,
    };

    pub const ManualAddress = extern struct {
        address: uefi.Ipv4Address,
        subnet_mask: uefi.Ipv4Address,
    };
};
