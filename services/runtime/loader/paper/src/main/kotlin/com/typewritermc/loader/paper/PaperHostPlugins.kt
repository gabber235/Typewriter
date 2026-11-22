package com.typewritermc.loader.paper

import com.typewritermc.imprint.EnabledPlugin
import com.typewritermc.loader.api.HostPlugins
import org.bukkit.plugin.PluginManager

/**
 * The plugins Paper's [pluginManager] has enabled now. Each read asks Paper again, so a plugin enabled or disabled at
 * runtime shows in the next presence answer and the Realm re-resolves this host's deployment.
 */
class PaperHostPlugins(
    private val pluginManager: PluginManager,
) : HostPlugins {
    override fun enabled(): List<EnabledPlugin> =
        pluginManager.plugins
            .filter { it.isEnabled }
            .map { EnabledPlugin(it.pluginMeta.name, it.pluginMeta.version) }

    override fun classLoader(name: String): ClassLoader? =
        pluginManager.getPlugin(name)?.takeIf { it.isEnabled }?.javaClass?.classLoader
}
