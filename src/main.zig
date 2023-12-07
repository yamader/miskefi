const app = @import("app/app.zig");
const common = @import("common.zig");
const uefi = @import("uefi.zig");

pub fn main() uefi.Status {
    var status = common.init();
    if (status != .Success) return status;

    app.app() catch return .Aborted;
    return .Success;
}
