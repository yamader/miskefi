const uefi = @import("std").os.uefi;

pub const Dhcp6ServiceBinding = extern struct {
    const Self = @This();

    _create_child: *const fn (*const Dhcp6ServiceBinding, *?uefi.Handle) callconv(uefi.cc) uefi.Status,
    _destroy_child: *const fn (*const Dhcp6ServiceBinding, uefi.Handle) callconv(uefi.cc) uefi.Status,

    pub fn createChild(self: *const Self, handle: *?uefi.Handle) uefi.Status {
        return self._create_child(self, handle);
    }

    pub fn destroyChild(self: *const Self, handle: uefi.Handle) uefi.Status {
        return self._destroy_child(self, handle);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x9fb9a8a1,
        .time_mid = 0x2f4a,
        .time_high_and_version = 0x43a6,
        .clock_seq_high_and_reserved = 0x88,
        .clock_seq_low = 0x9c,
        .node = [6]u8{ 0xd0, 0xf7, 0xb6, 0xc4, 0x7a, 0xd5 },
    };
};
