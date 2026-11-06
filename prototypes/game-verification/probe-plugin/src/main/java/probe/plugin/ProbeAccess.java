package probe.plugin;

import org.bukkit.plugin.Plugin;

final class ProbeAccess {
    private static Plugin plugin;

    private ProbeAccess() {}

    static void set(Plugin p) {
        plugin = p;
    }

    static Plugin plugin() {
        return plugin;
    }
}
