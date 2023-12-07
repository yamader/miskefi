const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "miskefi",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = .{
            .cpu_arch = .x86_64,
            .os_tag = .uefi,
        },
        .optimize = optimize,
    });

    const install = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install.step);

    const app = "zig-out/bin/miskefi.efi";
    const esp = "zig-cache/esp";

    const esp_cmd = b.addSystemCommand(&.{
        "sh", "-c",
        try std.fmt.allocPrint(b.allocator,
            \\mkdir -p {s}/EFI/BOOT && \
            \\cp {s} {s}/EFI/BOOT/BOOTx64.EFI
        , .{ esp, app, esp }),
    });
    esp_cmd.step.dependOn(&install.step);

    const bios = b.option(
        []const u8,
        "bios",
        "Path to OVMF_CODE.fd",
    ) orelse "/usr/share/edk2-ovmf/OVMF_CODE.fd";

    const qemu_cmd = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-drive",
        try std.fmt.allocPrint(b.allocator, "file={s},if=pflash,format=raw,readonly=on", .{bios}),
        "-drive",
        try std.fmt.allocPrint(b.allocator, "file=fat:rw:{s},format=raw", .{esp}),
        "-monitor",
        "stdio",
    });
    qemu_cmd.step.dependOn(&esp_cmd.step);
    if (b.args) |args| qemu_cmd.addArgs(args);

    const qemu = b.step("qemu", "Run the app in QEMU");
    qemu.dependOn(&qemu_cmd.step);
}
