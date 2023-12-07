const uefi = @import("std").os.uefi;

pub const Dhcp6 = extern struct {
    const Self = @This();

    _get_mode_data: *const fn (*const Dhcp6, *ModeData, *ConfigData) callconv(uefi.cc) uefi.Status,
    _configure: *const fn (*const Dhcp6, ?*const ConfigData) callconv(uefi.cc) uefi.Status,
    _start: *const fn (*const Dhcp6) callconv(uefi.cc) uefi.Status,
    _info_request: *const fn (*const Dhcp6, bool, *const PacketOption, u32, ?[*]*const PacketOption, *Retransmission, ?uefi.Event, InfoCallback, ?*anyopaque) callconv(uefi.cc) uefi.Status,
    _renew_rebind: *const fn (*const Dhcp6, bool) callconv(uefi.cc) uefi.Status,
    _decline: *const fn (*const Dhcp6, u32, *uefi.Ipv6Address) callconv(uefi.cc) uefi.Status,
    _release: *const fn (*const Dhcp6, u32, *uefi.Ipv6Address) callconv(uefi.cc) uefi.Status,
    _stop: *const fn (*const Dhcp6) callconv(uefi.cc) uefi.Status,
    _parse: *const fn (*const Dhcp6, *const Packet, *u32, ?[*]*PacketOption) callconv(uefi.cc) uefi.Status,

    pub fn getModeData(self: *const Self, mode_data: *ModeData, config_data: *ConfigData) uefi.Status {
        return self._get_mode_data(self, mode_data, config_data);
    }

    pub fn configure(self: *const Self, cfg_data: ?*const ConfigData) uefi.Status {
        return self._configure(self, cfg_data);
    }

    pub fn start(self: *const Self) uefi.Status {
        return self._start(self);
    }

    pub fn infoRequest(self: *const Self, send_client_id: bool, option_request: *const PacketOption, option_count: u32, option_list: ?[*]*const PacketOption, retransmission: *Retransmission, timeout_event: ?uefi.Event, reply_callback: InfoCallback, callback_context: ?*anyopaque) uefi.Status {
        return self.info_request(self, send_client_id, option_request, option_count, option_list, retransmission, timeout_event, reply_callback, callback_context);
    }

    pub fn renewRebind(self: *const Self, rebind_request: bool) uefi.Status {
        return self._renew_rebind(self, rebind_request);
    }

    pub fn decline(self: *const Self, address_count: u32, addresses: *uefi.Ipv6Address) uefi.Status {
        return self._decline(self, address_count, addresses);
    }

    pub fn release(self: *const Self, address_count: u32, addresses: *uefi.Ipv6Address) uefi.Status {
        return self._release(self, address_count, addresses);
    }

    pub fn stop(self: *const Self) uefi.Status {
        return self._stop(self);
    }

    pub fn parse(self: *const Self, packet: *const Packet, option_count: *u32, packet_option_list: ?[*]*PacketOption) uefi.Status {
        return self._parse(self, packet, option_count, packet_option_list);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x87c8bad7,
        .time_mid = 0x595,
        .time_high_and_version = 0x4053,
        .clock_seq_high_and_reserved = 0x82,
        .clock_seq_low = 0x97,
        .node = [6]u8{ 0xde, 0xde, 0x39, 0x5f, 0x5d, 0x5b },
    };

    pub const ModeData = extern struct {
        client_id: *Duid,
        ia: *Ia,
    };

    pub const Duid = extern struct {
        length: u16,
        duid: [1]u8,
    };

    pub const Ia = extern struct {
        descriptor: Descriptor,
        state: State,
        reply_packet: *Packet,
        ia_address_count: u32,
        ia_address: [1]Address,

        pub const Descriptor = extern struct {
            type: u16,
            ia_id: u32,
        };

        pub const type_na = 3;
        pub const type_ta = 4;

        pub const Address = extern struct {
            ip_address: uefi.Ipv6Address,
            preferred_lifetime: u32,
            valid_lifetime: u32,
        };
    };

    pub const State = enum(u32) {
        Init = 0x0,
        Selecting = 0x1,
        Requesting = 0x2,
        Declining = 0x3,
        Confirming = 0x4,
        Releasing = 0x5,
        Bound = 0x6,
        Renewing = 0x7,
        Rebinding = 0x8,
    };

    // pack(1)
    pub const Packet = extern struct {
        size: u32,
        length: u32,
        dhcp6: extern struct {
            header: Header align(1),
            option: [1]u8 align(1),
        } align(1),
    };

    pub const Header = packed struct {
        transaction_id: u24,
        message_type: u8,
    };

    pub const ConfigData = extern struct {
        dhcp6_callback: Callback,
        callback_context: *anyopaque,
        option_count: u32,
        option_list: *[*]PacketOption,
        ia_descriptor: Ia.Descriptor,
        ia_info_event: uefi.Event,
        reconfigure_accept: bool,
        rapid_commit: bool,
        solicit_retransmission: *Retransmission,
    };

    pub const Callback = *const fn (
        *const Dhcp6,
        *const anyopaque,
        State,
        Event,
        ?*const Packet,
        ?*[*]Packet,
    ) callconv(uefi.cc) uefi.Status;

    // pack(1)
    pub const PacketOption = extern struct {
        op_code: u16,
        op_len: u16,
        data: [1]u8,
    };

    pub const Event = enum(u32) {
        SendSolicit = 0x0,
        RcvdAdvertise = 0x1,
        SelectAdvertise = 0x2,
        SendRequest = 0x3,
        RcvdReply = 0x4,
        RcvdReconfigure = 0x5,
        SendDecline = 0x6,
        SendConfirm = 0x7,
        SendRelease = 0x8,
        SendRenew = 0x9,
        SendRebind = 0xa,
    };

    pub const Retransmission = extern struct {
        irt: u32,
        mrc: u32,
        mrt: u32,
        mrd: u32,
    };

    pub const InfoCallback = *const fn (
        *const Dhcp6,
        *const anyopaque,
        *const Packet,
    ) callconv(uefi.cc) uefi.Status;
};
