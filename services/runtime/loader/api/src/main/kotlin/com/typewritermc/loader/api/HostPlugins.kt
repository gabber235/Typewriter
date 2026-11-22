package com.typewritermc.loader.api

import com.typewritermc.imprint.EnabledPlugin

/**
 * The Paper plugins of the process that hosts the loader. The host reports [enabled] with its presence, so the Realm
 * decides which source parts its engines can run, and an engine loads a part that uses a plugin through that plugin's
 * [classLoader]. A host outside Paper has none.
 */
interface HostPlugins {
    /** The plugins enabled now, by the name and version Paper reports for each. */
    fun enabled(): List<EnabledPlugin>

    /** The class loader of the enabled plugin Paper reports as [name], or null when no such plugin is enabled. */
    fun classLoader(name: String): ClassLoader?

    /** The plugins of a host outside Paper: none. */
    data object None : HostPlugins {
        override fun enabled(): List<EnabledPlugin> = emptyList()

        override fun classLoader(name: String): ClassLoader? = null
    }
}
