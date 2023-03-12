const std = @import("std");
const builtin = @import("builtin");

/// Generates the plugin.zig file which serves as an entry point for plugin code into the gys execution.
/// All plugins must be located in the $HOME/.config/gys/plugins folder and must be buildable zig libraries.
/// The main zig class must be located at $HOME/.config/gys/"pluginname"/src/"pluginname".zig.
/// It can contain these function:
///     - onStartup(state: GysState, allocator: std.mem.Allocator)                  ---> A function which is executed at startup.
///     - onKeypress(state: GysState, keypress: u16, allocator: std.mem.Allocator)  ---> A function which is executed when a key is pressed.
///     - onClose(state: GysState, allocator: std.mem.Allocator)                    ---> A function which is executed when the application is being closed.
pub fn generatePluginEntryPoint(exe: *std.build.LibExeObjStep, allocator: std.mem.Allocator) void {
    const PluginFile = createPluginFile();

    const home_directory_path = optionalCheck([]const u8, "The HOME environment variable is not specified", std.os.getenv("HOME"), .{});
    const plugin_directory_path = errorCheck([]const u8, "Cannot generate the plugin directory", std.mem.concat(allocator, u8, &[_][]const u8{ home_directory_path, "/.config/gys/plugins/" }), .{});

    var plugin_directory = errorCheck(std.fs.IterableDir, "Cannot open the plugin directory {s}", std.fs.openIterableDirAbsolute(plugin_directory_path, .{}), .{plugin_directory_path});
    defer plugin_directory.close();

    var plugin_imports = errorCheck([]const u8, "Cannot allocate", allocator.alloc(u8, 0), .{});
    var plugin_list = errorCheck([]const u8, "Cannot allocate", allocator.alloc(u8, 0), .{});

    var iterator = plugin_directory.iterate();
    while (errorCheck(?std.fs.IterableDir.Entry, "An error occurred while iterating!", iterator.next(), .{})) |directory| {
        if (directory.kind != .Directory) {
            continue;
        }

        const plugin_path = generatePluginPath(plugin_directory_path, directory.name, allocator);
        defer allocator.free(plugin_path);

        exe.addPackagePath(directory.name, plugin_path);

        var tmp = plugin_imports;
        plugin_imports = addProjectImport(tmp, directory.name, allocator);
        allocator.free(tmp);

        tmp = plugin_list;
        plugin_list = addToProjectList(tmp, directory.name, allocator);
        allocator.free(tmp);
    }

    const plugin_list_without_trailing_comma = plugin_list[0 .. plugin_list.len - 1];
    writePluginFile(PluginFile, plugin_imports, plugin_list_without_trailing_comma, allocator);
    PluginFile.close();
}

fn addPluginDependencies(exe: *std.build.LibExeObjStep, plugin_path: []const u8, allocator: std.mem.Allocator) void {
    const deps_file_path = errorCheck([]const u8, "Cannot generate the sysdeps file path!", std.mem.concat(allocator, u8, &[_][]const u8{ plugin_path, "/.deps" }), .{});
    var file = std.fs.openFileAbsolute(deps_file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // A line should never be longer than 255 characters
    var buf: [255]u8 = undefined;
    while (errorCheck([]const u8, "Could not read line!", in_stream.readUntilDelimiterOrEof(&buf, '\n'), .{})) |line| {
        var packageName = errorCheck([]const u8, "Cannot allocate!", allocator.alloc(u8, 0), .{});
        var packagePath = errorCheck([]const u8, "Cannot allocate!", allocator.alloc(u8, 0), .{});

        var i: u8 = 0;
        while ((line[i] == ' ' or line[i] == '\t') and i < line.len) : (i += 1) {}

        while ((line[i] != ':' or line[i] == ' ' or line[i] == '\t') and i < line.len) : (i += 1) {
            var tmp = packageName;
            defer allocator.free(tmp);
            errorCheck([]const u8, "Cannot append to the Package Name", std.mem.concat(allocator, u8, &[_][]const u8{ tmp, [1]u8{line[i]} }), .{});
        }

        while ((line[i] == ' ' or line[i] == '\t' or line[i] == ':') and i < line.len) : (i += 1) {}

        while ((line[i] != ' ' or line[i] != '\t') and i < line.len) : (i += 1) {
            errorCheck([]const u8, "Cannot append to the Package Path", std.mem.concat(allocator, u8, &[_][]const u8{ tmp, [1]u8{line[i]} }), .{});
        }

        exe.addPackagePath(packageName, packagePath);
    }
}

/// Creates an empty plugins.zig file.
fn createPluginFile() std.fs.File {
    return std.fs.cwd().createFile("exe/plugins.zig", .{}) catch {
        _ = errorCheck(void, "Can not delete the exe/plugins.zig file!", std.fs.cwd().deleteFile("exe/plugins.zig"), .{});
        return errorCheck(std.fs.File, "Can not create the exe/plugins.zig file!", std.fs.cwd().createFile("exe/plugins.zig", .{}), .{});
    };
}

/// Writes to the plugin file the contents of the imports and the project list.
fn writePluginFile(file: std.fs.File, imports: []const u8, list: []const u8, allocator: std.mem.Allocator) void {
    const writer = file.writer();
    _ = errorCheck(usize, "Cannot write to file plugins.zig", writer.write("// These following import statements are all plugins which are currently used by gys editor. To add a new one, just create a plugin at $HOME/.config/gys/plugins/\"pluginname\"\n"), .{});
    _ = errorCheck(usize, "Cannot write to file plugins.zig", writer.write(imports), .{});
    _ = errorCheck(usize, "Cannot write to file plugins.zig", writer.write("\n\n // This array holds the execution type of each plugin.\n"), .{});
    _ = errorCheck(usize, "Cannot write to file plugins.zig", writer.write(errorCheck([]const u8, "Cannot generate plugin list", std.mem.concat(allocator, u8, &[_][]const u8{ "pub const PluginList = []type{", list, "};" }), .{})), .{});
}

/// Adds a project to the projects import list in the plugins.zig file.
fn addProjectImport(string: []const u8, name: []const u8, allocator: std.mem.Allocator) []const u8 {
    return errorCheck([]const u8, "Cannot add plugin import!", std.mem.concat(allocator, u8, &[_][]const u8{ string, "pub const ", name, " = @import(\"", name, "\");\n" }), .{});
}

/// Adds a project to the projects list in the plugins.zig file.
fn addToProjectList(string: []const u8, name: []const u8, allocator: std.mem.Allocator) []const u8 {
    return errorCheck([]const u8, "Cannot add plugin to plugin list!", std.mem.concat(allocator, u8, &[_][]const u8{ string, name, "," }), .{});
}

/// Generates the path to the main executable of a plugin.
fn generatePluginPath(plugin_directory: []const u8, plugin_name: []const u8, allocator: std.mem.Allocator) []const u8 {
    return errorCheck([]const u8, "Cannot generate the path to the plugin!", std.mem.concat(allocator, u8, &[_][]const u8{ plugin_directory, plugin_name, "/src/", plugin_name, ".zig" }), .{});
}

/// During build we do not want to use optional types, we want to throw compile time errors.
fn optionalCheck(comptime T: type, comptime message: []const u8, optional: anytype, params: anytype) T {
    return optional orelse {
        const ansi_red = "\x1b[31m";
        std.debug.print(ansi_red ++ message ++ "\n", params);
        unreachable;
    };
}

/// During build we do not want to use error types, we want to throw compile time errors.
fn errorCheck(comptime T: type, comptime message: []const u8, possible_error: anytype, params: anytype) T {
    return possible_error catch {
        const ansi_red = "\x1b[31m";
        std.debug.print(ansi_red ++ message ++ "\n", params);
        unreachable;
    };
}
