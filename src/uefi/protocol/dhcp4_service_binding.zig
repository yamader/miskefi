const uefi = @import("std").os.uefi;

pub const Dhcp4ServiceBinding = extern struct {
    const Self = @This();

    _create_child: *const fn (*const Dhcp4ServiceBinding, *?uefi.Handle) callconv(uefi.cc) uefi.Status,
    _destroy_child: *const fn (*const Dhcp4ServiceBinding, uefi.Handle) callconv(uefi.cc) uefi.Status,

    pub fn createChild(self: *const Self, handle: *?uefi.Handle) uefi.Status {
        return self._create_child(self, handle);
    }

    pub fn destroyChild(self: *const Self, handle: uefi.Handle) uefi.Status {
        return self._destroy_child(self, handle);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x9d9a39d8,
        .time_mid = 0xbd42,
        .time_high_and_version = 0x4a73,
        .clock_seq_high_and_reserved = 0xa4,
        .clock_seq_low = 0xd5,
        .node = [6]u8{ 0x8e, 0xe9, 0x4b, 0xe1, 0x13, 0x80 },
    };
};
