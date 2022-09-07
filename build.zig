const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    b.prominent_compile_errors = true; // hide backtrace on compile error
    b.use_stage1 = true;
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const rustlib = cargo(b);

    const exe = b.addExecutable("zFFI", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addLibPath("target/release");
    exe.linkSystemLibraryName("zFFI");
    exe.linkLibC();
    exe.addPackagePath("binding", "generated/binding.zig");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const cargo_step = b.step("cargo", "Run cargo build");
    cargo_step.dependOn(&rustlib.step);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const tests = b.addTest("src/main.zig");
    tests.setTarget(target);
    tests.setBuildMode(mode);
    tests.addLibPath("target/release");
    tests.linkSystemLibraryName("zFFI");
    tests.linkLibC();
    tests.addPackagePath("binding", "generated/binding.zig");

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&tests.step);
}

fn cargo(b: *std.build.Builder) *std.build.RunStep {
    return b.addSystemCommand(&[_][]const u8{
        "cargo",
        "build",
        "--release",
    });
}
