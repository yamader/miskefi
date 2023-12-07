const uefi = @import("std").os.uefi;

pub usingnamespace uefi;

pub const protocol = struct {
    pub usingnamespace @import("uefi/protocol.zig");

    pub const LoadedImage = uefi.protocols.LoadedImageProtocol;
    pub const DevicePath = uefi.protocols.DevicePathProtocol;
    pub const SimpleTextInput = uefi.protocols.SimpleTextInputProtocol;
    pub const SimpleTextOutput = uefi.protocols.SimpleTextOutputProtocol;
    pub const GraphicsOutput = uefi.protocols.GraphicsOutputProtocol;
};
