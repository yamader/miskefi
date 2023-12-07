const uefi = @import("std").os.uefi;

pub const HttpServiceBinding = extern struct {
    const Self = @This();

    _create_child: *const fn (*const HttpServiceBinding, *?uefi.Handle) callconv(uefi.cc) uefi.Status,
    _destroy_child: *const fn (*const HttpServiceBinding, uefi.Handle) callconv(uefi.cc) uefi.Status,

    pub fn createChild(self: *const Self, handle: *?uefi.Handle) uefi.Status {
        return self._create_child(self, handle);
    }

    pub fn destroyChild(self: *const Self, handle: uefi.Handle) uefi.Status {
        return self._destroy_child(self, handle);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0xbdc8e6af,
        .time_mid = 0xd9bc,
        .time_high_and_version = 0x4379,
        .clock_seq_high_and_reserved = 0xa7,
        .clock_seq_low = 0x2a,
        .node = [6]u8{ 0xe0, 0xc4, 0xe7, 0x5d, 0xae, 0x1c },
    };
};
