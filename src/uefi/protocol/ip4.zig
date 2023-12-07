const uefi = @import("std").os.uefi;

const ManagedNetworkConfigData = uefi.protocols.ManagedNetworkConfigData;
const SimpleNetworkMode = uefi.protocols.SimpleNetworkMode;

pub const Ip4 = extern struct {
    const Self = @This();

    _get_mode_data: *const fn (*const Ip4, ?*ModeData, ?*ManagedNetworkConfigData, ?*SimpleNetworkMode) callconv(uefi.cc) uefi.Status,
    _configure: *const fn (*const Ip4, ?*const ConfigData) callconv(uefi.cc) uefi.Status,
    _groups: *const fn (*const Ip4, bool, ?*const uefi.Ipv4Address) callconv(uefi.cc) uefi.Status,
    _routes: *const fn (*const Ip4, bool, *const uefi.Ipv4Address, *const uefi.Ipv4Address, *const uefi.Ipv4Address) callconv(uefi.cc) uefi.Status,
    _transmit: *const fn (*const Ip4, *const CompletionToken) callconv(uefi.cc) uefi.Status,
    _receive: *const fn (*const Ip4, token: *const CompletionToken) callconv(uefi.cc) uefi.Status,
    _cancel: *const fn (*const Ip4, ?*const CompletionToken) callconv(uefi.cc) uefi.Status,
    _poll: *const fn (*const Ip4) callconv(uefi.cc) uefi.Status,

    pub fn getModeData(self: *const Self, mode_data: ?*ModeData, mnp_config_data: ?*ManagedNetworkConfigData, snp_mode_data: ?(SimpleNetworkMode)) uefi.Status {
        return self._get_mode_data(self, mode_data, mnp_config_data, snp_mode_data);
    }

    pub fn configure(self: *const Self, config_data: ?*uefi.Ipv4Address) uefi.Status {
        return self._configure(self, config_data);
    }

    pub fn groups(self: *const Self, join_flag: bool, group_address: ?*uefi.Ipv4Address) uefi.Status {
        return self._groups(self, join_flag, group_address);
    }

    pub fn routes(self: *const Self, delete_route: bool, subnet_address: *uefi.Ipv4Address, subnet_mask: *uefi.Ipv4Addressm, gateway_address: *uefi.Ipv4Address) uefi.Status {
        return self._routes(self, delete_route, subnet_address, subnet_mask, gateway_address);
    }

    pub fn transmit(self: *const Self, token: *const CompletionToken) uefi.Status {
        return self._transmit(self, token);
    }

    pub fn receive(self: *const Self, token: *const CompletionToken) uefi.Status {
        return self._receive(self, token);
    }

    pub fn cancel(self: *const Self, token: ?*const CompletionToken) uefi.Status {
        return self._cancel(self, token);
    }

    pub fn poll(self: *const Self) uefi.Status {
        return self._poll(self);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x41d94cd2,
        .time_mid = 0x35b6,
        .time_high_and_version = 0x455a,
        .clock_seq_high_and_reserved = 0x82,
        .clock_seq_low = 0x58,
        .node = [6]u8{ 0xd4, 0xe5, 0x13, 0x34, 0xaa, 0xdd },
    };

    pub const ModeData = extern struct {
        is_started: bool,
        max_packet_size: u32,
        config_data: ConfigData,
        is_configured: bool,
        group_count: u32,
        group_table: [*]uefi.Ipv4Address,
        route_count: u32,
        route_table: RouteTable,
        icmp_type_count: u32,
        icmp_type_list: IcmpType,
    };

    pub const ConfigData = extern struct {
        default_protocol: u8,
        accept_any_protocol: bool,
        accept_icmp_errors: bool,
        accept_broadcast: bool,
        accept_promiscuous: bool,
        use_default_address: bool,
        station_address: uefi.Ipv4Address,
        subnet_mask: uefi.Ipv4Address,
        type_of_service: u8,
        time_to_live: u8,
        do_not_fragment: bool,
        raw_data: bool,
        receive_timeout: u32,
        transmit_timeout: u32,
    };

    pub const RouteTable = extern struct {
        subnet_address: uefi.Ipv4Address,
        subnet_mask: uefi.Ipv4Address,
        gateway_address: uefi.Ipv4Address,
    };

    pub const IcmpType = extern struct {
        type: u8,
        code: u8,
    };

    pub const CompletionToken = extern struct {
        event: uefi.Event,
        status: uefi.Status,
        packet: extern union {
            rx_data: *ReceiveData,
            tx_data: *TransmitData,
        },
    };

    pub const ReceiveData = extern struct {
        time_stamp: uefi.Time,
        recycle_signal: uefi.Event,
        header_length: u32,
        header: *anyopaque, // Header
        options_length: u32,
        options: *anyopaque,
        data_length: u32,
        fragment_count: u32,
        fragment_table: [1]FragmentData,
    };

    // pack(1)
    // pub const Header = extern struct {};

    pub const FragmentData = extern struct {
        fragment_length: u32,
        fragment_buffer: *anyopaque,
    };

    pub const TransmitData = extern struct {
        destination_address: uefi.Ipv4Address,
        override_data: *OverrideData,
        options_length: u32,
        options_buffer: *anyopaque,
        total_data_length: u32,
        fragment_count: u32,
        fragment_table: [1]FragmentData,
    };

    pub const OverrideData = extern struct {
        source_address: uefi.Ipv4Address,
        gateway_address: uefi.Ipv4Address,
        protocol: u8,
        type_of_service: u8,
        time_to_live: u8,
        do_not_fragment: bool,
    };
};
