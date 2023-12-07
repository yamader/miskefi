const uefi = @import("std").os.uefi;

pub const Dhcp4 = extern struct {
    const Self = @This();

    _get_mode_data: *const fn (*const Dhcp4, *ModeData) callconv(uefi.cc) uefi.Status,
    _configure: *const fn (*const Dhcp4, ?*const ConfigData) callconv(uefi.cc) uefi.Status,
    _start: *const fn (*const Dhcp4, ?uefi.Event) callconv(uefi.cc) uefi.Status,
    _renew_rebind: *const fn (*const Dhcp4, bool, ?uefi.Event) callconv(uefi.cc) uefi.Status,
    _release: *const fn (*const Dhcp4) callconv(uefi.cc) uefi.Status,
    _stop: *const fn (*const Dhcp4) callconv(uefi.cc) uefi.Status,
    _build: *const fn (*const Dhcp4, *const Packet, u32, ?*u8, u32, ?[*]*PacketOption, *[*]Packet) callconv(uefi.cc) uefi.Status,
    _transmit_receive: *const fn (*const Dhcp4, *TransmitReceiveToken) callconv(uefi.cc) uefi.Status,
    _parse: *const fn (*const Dhcp4, *const Packet, *u32, ?[*]*PacketOption) callconv(uefi.cc) uefi.Status,

    pub fn getModeData(self: *const Self, mode_data: *ModeData) uefi.Status {
        return self._get_mode_data(self, mode_data);
    }

    pub fn configure(self: *const Self, cfg_data: ?*const ConfigData) uefi.Status {
        return self._configure(self, cfg_data);
    }

    pub fn start(self: *const Self, completion_event: ?uefi.Event) uefi.Status {
        return self._start(self, completion_event);
    }

    pub fn renewRebind(self: *const Self, rebind_request: bool, completion_event: ?uefi.Event) uefi.Status {
        return self._renew_rebind(self, rebind_request, completion_event);
    }

    pub fn release(self: *const Self) uefi.Status {
        return self._release(self);
    }

    pub fn stop(self: *const Self) uefi.Status {
        return self._stop(self);
    }

    pub fn build(self: *const Self, seed_packet: *const Packet, delete_count: u32, delete_list: ?*u8, append_count: u32, append_list: ?[*]*PacketOption, new_packet: *[*]Packet) uefi.Status {
        return self._build(self, seed_packet, delete_count, delete_list, append_count, append_list, new_packet);
    }

    pub fn transmitReceive(self: *const Self, token: *TransmitReceiveToken) uefi.Status {
        return self._transmit_receive(self, token);
    }

    pub fn parse(self: *const Self, packet: *const Packet, option_count: *u32, packet_option_list: ?[*]*PacketOption) uefi.Status {
        return self._parse(self, packet, option_count, packet_option_list);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x8a219718,
        .time_mid = 0x4ef5,
        .time_high_and_version = 0x4761,
        .clock_seq_high_and_reserved = 0x91,
        .clock_seq_low = 0xc8,
        .node = [6]u8{ 0xc0, 0xf0, 0x4b, 0xda, 0x9e, 0x56 },
    };

    pub const ModeData = extern struct {
        state: State,
        config_data: ConfigData,
        client_address: uefi.Ipv4Address,
        client_mac_address: uefi.MacAddress,
        server_address: uefi.Ipv4Address,
        router_address: uefi.Ipv4Address,
        subnet_mask: uefi.Ipv4Address,
        lease_time: u32,
        reply_packet: *Packet,
    };

    pub const State = enum(u32) {
        Stopped = 0x0,
        Init = 0x1,
        Selecting = 0x2,
        Requesting = 0x3,
        Bound = 0x4,
        Renewing = 0x5,
        Rebinding = 0x6,
        InitReboot = 0x7,
        Rebooting = 0x8,
    };

    // pack(1)
    pub const Packet = extern struct {
        size: u32,
        length: u32,
        dhcp4: extern struct {
            header: Header align(1),
            magik: u32 align(1),
            option: [1]u8 align(1),
        } align(1),
    };

    pub const ConfigData = extern struct {
        discover_try_count: u32,
        discover_timeout: *u32,
        request_try_count: u32,
        request_timeout: *u32,
        client_address: uefi.Ipv4Address,
        dhcp4_callback: Callback,
        callback_context: *anyopaque,
        option_count: u32,
        option_list: *[*]PacketOption,
    };

    pub const Callback = *const fn (
        *const Dhcp4,
        *const anyopaque,
        State,
        Event,
        ?*const Packet,
        ?*[*]Packet,
    ) callconv(uefi.cc) uefi.Status;

    pub const Event = enum(u32) {
        SendDiscover = 0x01,
        RcvdOffer = 0x02,
        SelectOffer = 0x03,
        SendRequest = 0x04,
        RcvdAck = 0x05,
        RcvdNak = 0x06,
        SendDecline = 0x07,
        BoundCompleted = 0x08,
        EnterRenewing = 0x09,
        EnterRebinding = 0x0a,
        AddressLost = 0x0b,
        Fail = 0x0c,
    };

    // pack(1)
    pub const Header = extern struct {
        op_code: u8,
        hw_type: u8,
        hw_addr_len: u8,
        hops: u8,
        xid: u32,
        seconds: u16,
        reserved: u16,
        client_addr: uefi.Ipv4Address align(1),
        your_addr: uefi.Ipv4Address align(1),
        server_addr: uefi.Ipv4Address align(1),
        gateway_addr: uefi.Ipv4Address align(1),
        client_hw_addr: [16]u8 align(1),
        server_name: [64]u8 align(1),
        boot_file_name: [128]u8 align(1),
    };

    // pack(1)
    pub const PacketOption = extern struct {
        op_code: u8,
        length: u8,
        data: [1]u8,
    };

    pub const TransmitReceiveToken = extern struct {
        status: uefi.Status,
        completion_event: uefi.Event,
        remote_address: uefi.Ipv4Address,
        remote_port: u16,
        gateway_address: uefi.Ipv4Address,
        listen_point_count: u32,
        listen_points: *ListenPoint,
        timeout_value: u32,
        packet: *Packet,
        response_count: u32,
        response_list: *Packet,
    };

    pub const ListenPoint = extern struct {
        listen_address: uefi.Ipv4Address,
        subnet_mask: uefi.Ipv4Address,
        listen_port: u16,
    };
};
