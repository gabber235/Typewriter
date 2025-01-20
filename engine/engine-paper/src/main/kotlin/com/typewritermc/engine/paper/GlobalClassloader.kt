@file:Suppress("UnstableApiUsage")

package com.typewritermc.engine.paper

import io.papermc.paper.plugin.provider.classloader.ConfiguredPluginClassLoader
import io.papermc.paper.plugin.provider.classloader.PaperClassLoaderStorage
import io.papermc.paper.plugin.provider.classloader.PluginClassLoaderGroup

/**
 * The global classloader is used for extensions.
 *
 * Paper separates the classloaders in plugins to not be able to load classes from other plugins.
 * This means that Extensions wouldn't be able to load classes from other plugins.
 * This is unacceptable as extensions are meant to use code from other plugins.
 *
 * To solve this, we hack around the Paper classloader system to get a classloader that has access to all classes.
 */
class GlobalClassloader(
    private val group: PluginClassLoaderGroup,
    private val requester: ConfiguredPluginClassLoader,
) : ClassLoader() {
    override fun loadClass(name: String, resolve: Boolean): Class<*> {
        return group.getClassByName(name, resolve, requester) ?: super.loadClass(name, resolve)
    }
}

internal fun globalClassloader(): GlobalClassloader {
    val storage = PaperClassLoaderStorage.instance()

    val group = storage.javaClass.getDeclaredMethod("getGlobalGroup").invoke(storage) as PluginClassLoaderGroup
    val requester = plugin.javaClass.classLoader as ConfiguredPluginClassLoader

    return GlobalClassloader(group, requester)
}
