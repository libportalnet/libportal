// zig fmt: off
const std = @import("std");
const builtin = @import("builtin");
const string = []const u8;
const ModuleDependency = std.build.ModuleDependency;

pub const cache = ".zigmod/deps";

pub fn addAllTo(exe: *std.build.LibExeObjStep) void {
    checkMinZig(builtin.zig_version, exe);
    const b = exe.step.owner;
    @setEvalBranchQuota(1_000_000);
    for (packages) |pkg| {
        const moddep = pkg.zp(b);
        exe.addModule(moddep.name, moddep.module);
    }
    addAllLibrariesTo(exe);
}

pub fn addAllLibrariesTo(exe: *std.build.LibExeObjStep) void {
    const b = exe.step.owner;
    var llc = false;
    var vcpkg = false;
    inline for (comptime std.meta.declarations(package_data)) |decl| {
        const pkg = @as(Package, @field(package_data, decl.name));
        for (pkg.system_libs) |item| {
            exe.linkSystemLibrary(item);
            llc = true;
        }
        for (pkg.frameworks) |item| {
            if (!builtin.target.isDarwin()) @panic(b.fmt("a dependency is attempting to link to the framework {s}, which is only possible under Darwin", .{item}));
            exe.linkFramework(item);
            llc = true;
        }
        for (pkg.c_include_dirs) |item| {
            exe.addIncludePath(.{.path = b.fmt("{s}/{s}", .{ @field(dirs, decl.name), item })});
            llc = true;
        }
        for (pkg.c_source_files) |item| {
            exe.addCSourceFile(.{ .file = .{ .path = b.fmt("{s}/{s}", .{ @field(dirs, decl.name), item }) }, .flags = pkg.c_source_flags });
            llc = true;
        }
        vcpkg = vcpkg or pkg.vcpkg;
    }
    if (llc) exe.linkLibC();
    if (builtin.os.tag == .windows and vcpkg) exe.addVcpkgPaths(.static) catch |err| @panic(@errorName(err));
}

pub const Package = struct {
    directory: string,
    pkg: ?Pkg = null,
    c_include_dirs: []const string = &.{},
    c_source_files: []const string = &.{},
    c_source_flags: []const string = &.{},
    system_libs: []const string = &.{},
    frameworks: []const string = &.{},
    vcpkg: bool = false,
    module: ?ModuleDependency = null,

    pub fn zp(self: *Package, b: *std.build.Builder) ModuleDependency {
        var temp: [100]ModuleDependency = undefined;
        const pkg = self.pkg.?;
        for (pkg.dependencies, 0..) |item, i| {
            temp[i] = item.zp(b);
        }
        if (self.module) |mod| {
            return mod;
        }
        const result = ModuleDependency{
            .name = pkg.name,
            .module = b.createModule(.{
                .source_file = pkg.source,
                .dependencies = b.allocator.dupe(ModuleDependency, temp[0..pkg.dependencies.len]) catch @panic("oom"),
            }),
        };
        self.module = result;
        return result;
    }
};

pub const Pkg = struct {
    name: string,
    source: std.build.FileSource,
    dependencies: []const *Package,
};

fn checkMinZig(current: std.SemanticVersion, exe: *std.build.LibExeObjStep) void {
    const min = std.SemanticVersion.parse("0.11.0") catch return;
    if (current.order(min).compare(.lt)) @panic(exe.step.owner.fmt("Your Zig version v{} does not meet the minimum build requirement of v{}", .{current, min}));
}

pub const dirs = struct {
    pub const _root = "";
    pub const _x7g8qpk2bzq1 = cache ++ "/../..";
    pub const _c47gvf1ymvjv = cache ++ "/git/github.com/mitchellh/libxev";
    pub const _e9rgqrtrxhfe = cache ++ "/git/github.com/Hejsil/zig-bench";
};

pub const package_data = struct {
    pub var _x7g8qpk2bzq1 = Package{
        .directory = dirs._x7g8qpk2bzq1,
        .pkg = Pkg{ .name = "lobo", .source = .{ .path = dirs._x7g8qpk2bzq1 ++ "/src/main.zig" }, .dependencies = &.{} },
    };
    pub var _c47gvf1ymvjv = Package{
        .directory = dirs._c47gvf1ymvjv,
        .pkg = Pkg{ .name = "libxev", .source = .{ .path = dirs._c47gvf1ymvjv ++ "/src/main.zig" }, .dependencies = &.{} },
    };
    pub var _e9rgqrtrxhfe = Package{
        .directory = dirs._e9rgqrtrxhfe,
        .pkg = Pkg{ .name = "bench", .source = .{ .path = dirs._e9rgqrtrxhfe ++ "/bench.zig" }, .dependencies = &.{} },
    };
    pub var _root = Package{
        .directory = dirs._root,
    };
};

pub const packages = &[_]*Package{
    &package_data._x7g8qpk2bzq1,
    &package_data._c47gvf1ymvjv,
    &package_data._e9rgqrtrxhfe,
};

pub const pkgs = struct {
    pub const lobo = &package_data._x7g8qpk2bzq1;
    pub const libxev = &package_data._c47gvf1ymvjv;
    pub const bench = &package_data._e9rgqrtrxhfe;
};

pub const imports = struct {
};
