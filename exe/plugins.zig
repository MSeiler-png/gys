// These following import statements are all plugins which are currently used by gys editor. To add a new one, just create a plugin at $HOME/.config/gys/plugins/"pluginname"
pub const lsp = @import("lsp");


 // This array holds the execution type of each plugin.
pub const PluginList = []type{lsp};