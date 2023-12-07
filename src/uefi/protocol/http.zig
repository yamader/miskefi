const uefi = @import("std").os.uefi;

pub const Http = extern struct {
    const Self = @This();

    _get_mode_data: *const fn (*const Http, *ConfigData) callconv(uefi.cc) uefi.Status,
    _configure: *const fn (*const Http, ?*const ConfigData) callconv(uefi.cc) uefi.Status,
    _request: *const fn (*const Http, *const Token) callconv(uefi.cc) uefi.Status,
    _cancel: *const fn (*const Http, *const Token) callconv(uefi.cc) uefi.Status,
    _response: *const fn (*const Http, *const Token) callconv(uefi.cc) uefi.Status,
    _poll: *const fn (*const Http) callconv(uefi.cc) uefi.Status,

    pub fn getModeData(self: *const Self, config_data: *ConfigData) uefi.Status {
        return self._get_mode_data(self, config_data);
    }

    pub fn configure(self: *const Self, config_data: ?*const ConfigData) uefi.Status {
        return self._configure(self, config_data);
    }

    pub fn request(self: *const Self, token: *const Token) uefi.Status {
        return self._request(self, token);
    }

    pub fn cancel(self: *const Self, token: *const Token) uefi.Status {
        return self._cancel(self, token);
    }

    pub fn response(self: *const Self, token: *const Token) uefi.Status {
        return self._response(self, token);
    }

    pub fn poll(self: *const Self) uefi.Status {
        return self._poll(self);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x7a59b29b,
        .time_mid = 0x910b,
        .time_high_and_version = 0x4171,
        .clock_seq_high_and_reserved = 0x82,
        .clock_seq_low = 0x42,
        .node = [6]u8{ 0xa8, 0x5a, 0x0d, 0xf2, 0x5b, 0x5b },
    };

    pub const ConfigData = extern struct {
        http_version: Version,
        time_out_millisec: u32,
        local_address_is_ipv6: bool,
        access_point: extern union {
            ipv4_node: *V4AccessPoint,
            ipv6_node: *V6AccessPoint,
        },
    };

    pub const Version = enum(u32) {
        _10,
        _11,
        Unsupported,
    };

    pub const V4AccessPoint = extern struct {
        use_default_address: bool,
        local_address: uefi.Ipv4Address,
        local_subnet: uefi.Ipv4Address,
        local_port: u16,
    };

    pub const V6AccessPoint = extern struct {
        local_address: uefi.Ipv6Address,
        local_port: u16,
    };

    pub const Token = extern struct {
        event: uefi.Event,
        status: uefi.Status,
        message: *Message,
    };

    pub const Message = extern struct {
        data: extern union {
            request: *RequestData,
            response: *ResponseData,
        },
        header_count: usize,
        headers: [*]Header,
        body_length: usize,
        body: ?[*]u8,
    };

    pub const RequestData = extern struct {
        method: Method,
        url: [*]u16,
    };

    pub const Method = enum(u32) {
        Get,
        Post,
        Patch,
        Options,
        Connect,
        Head,
        Put,
        Delete,
        Trace,
        Max,
    };

    pub const ResponseData = extern struct {
        status_code: StatusCode,
    };

    pub const Header = extern struct {
        field_name: [*:0]u8,
        field_value: [*:0]u8,
    };

    pub const StatusCode = enum(u32) {
        UnsupportedStatus = 0,
        _100_Continue,
        _101_SwitchingProtocols,
        _200_Ok,
        _201_Created,
        _202_Accepted,
        _203_NonAuthoritativeInformation,
        _204_NoContent,
        _205_ResetContent,
        _206_PartialContent,
        _300_MultipleChoices,
        _301_MovedPermanently,
        _302_Found,
        _303_SeeOther,
        _304_NotModified,
        _305_UseProxy,
        _307_TemporaryRedirect,
        _400_BadRequest,
        _401_Unauthorized,
        _402_PaymentRequired,
        _403_Forbidden,
        _404_NotFound,
        _405_MethodNotAllowed,
        _406_NotAcceptable,
        _407_ProxyAuthenticationRequired,
        _408_RequestTimeOut,
        _409_Conflict,
        _410_Gone,
        _411_LengthRequired,
        _412_PreconditionFailed,
        _413_RequestEntityTooLarge,
        _414_RequestUriTooLarge,
        _415_UnsupportedMediaType,
        _416_RequestedRangeNotSatisfied,
        _417_ExpectationFailed,
        _500_InternalServerError,
        _501_NotImplemented,
        _502_BadGateway,
        _503_ServiceUnavailable,
        _504_GatewayTimeOut,
        _505_HttpVersionNotSupported,
        _308_PermanentRedirect,
    };
};
