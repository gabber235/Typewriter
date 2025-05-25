package com.typewritermc.worldguard

import com.sk89q.worldguard.WorldGuard
import com.sk89q.worldguard.bukkit.WorldGuardPlugin
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.server

@Singleton
class WorldGuardInitializer : Initializable {
    private val factory = WorldGuardHandler.Factory

    override suspend fun initialize() {
        val worldGuard = WorldGuard.getInstance()

        val registered = worldGuard.platform.sessionManager.registerHandler(factory, null)

        if (!registered) {
            logger.warning("Failed to register WorldGuardHandler. This is a bug, please report it on the Typewriter Discord.")
            return
        }
        val worldGuardPlugin = server.pluginManager.getPlugin("WorldGuard") as? WorldGuardPlugin
        if (worldGuardPlugin == null) {
            logger.warning("WorldGuard plugin not found, so WorldGuard will not be enabled.")
            return
        }

        // This is a hack to fix a shortcomming in WorldGuard.
        // WorldGuard does not register the handler to ongoing sessions.
        // So we need to manually register the handler to all active sessions when the extension is reloaded.
        server.onlinePlayers.forEach { player ->
            val bukkitPlayer = WorldGuardPlugin.inst().wrapPlayer(player)
            worldGuard.platform.sessionManager.getIfPresent(bukkitPlayer)?.let { session ->
                val currentHandler = session.getHandler(WorldGuardHandler::class.java)
                if (currentHandler != null) {
                    return@forEach
                }
                session.register(factory.create(session))
            }
        }
    }

    override suspend fun shutdown() {
        WorldGuard.getInstance().platform.sessionManager.unregisterHandler(factory)

        // This is a hack to fix a shortcomming in WorldGuard.
        // WorldGuard does not unregister the handler from ongoing sessions.
        // So we need to manually unregister the handler from all sessions.
        server.onlinePlayers.forEach { player ->
            val bukkitPlayer = WorldGuardPlugin.inst().wrapPlayer(player)
            WorldGuard.getInstance().platform.sessionManager.getIfPresent(bukkitPlayer)?.let { session ->
                session::class.java.getDeclaredField("handlers").apply {
                    isAccessible = true
                    val handlers = get(session) as MutableMap<Class<*>, Any>
                    handlers.remove(WorldGuardHandler::class.java)
                }
            }
        }
    }
}