package com.typewritermc.engine.paper.extensions.placeholderapi

import com.typewritermc.core.entries.Query
import com.typewritermc.core.utils.Reloadable
import com.typewritermc.engine.paper.entry.PlaceholderEntry
import com.typewritermc.engine.paper.entry.PlaceholderParser
import com.typewritermc.engine.paper.utils.server
import me.clip.placeholderapi.PlaceholderAPI
import me.clip.placeholderapi.expansion.PlaceholderExpansion
import org.bukkit.OfflinePlayer
import org.bukkit.entity.Player
import org.bukkit.plugin.Plugin
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.*
import java.util.concurrent.ConcurrentHashMap


object PlaceholderExpansion : PlaceholderExpansion(), KoinComponent, Reloadable {
    private val plugin: Plugin by inject()
    override fun getIdentifier(): String = "typewriter"

    override fun getAuthor(): String = "gabber235"

    override fun getVersion(): String = plugin.pluginMeta.version

    override fun persist(): Boolean = true

    override suspend fun load() = cachedParsers.clear()
    override suspend fun unload() = cachedParsers.clear()

    private val cachedParsers: ConcurrentHashMap<String, PlaceholderParser> =
        ConcurrentHashMap<String, PlaceholderParser>()

    override fun onPlaceholderRequest(player: Player?, params: String): String? {
        val handlers = getKoin().getAll<PlaceholderHandler>()
        val result = handlers.asSequence()
            .mapNotNull { it.onPlaceholderRequest(player, params) }
            .firstOrNull()
        if (result != null) return result

        val parts = params.split(':')
        val id = parts[0]

        val parser = cachedParsers.getOrPut(id) {
            val entry: PlaceholderEntry = Query.findById(id) ?: Query.findByName(id) ?: return null
            entry.parser()
        }

        return parser.parse(player, parts.subList(1, parts.size))
    }
}

fun String.parsePlaceholders(player: OfflinePlayer?): String {
    return if (server.pluginManager.isPluginEnabled("PlaceholderAPI")) {
        PlaceholderAPI.setPlaceholders(player, this)
    } else this
}

fun String.parsePlaceholders(player: Player?): String = parsePlaceholders(player as OfflinePlayer?)

fun String.parsePlaceholders(playerId: UUID): String = parsePlaceholders(server.getOfflinePlayer(playerId))

val String.isPlaceholder: Boolean
    get() {
        return if (server.pluginManager.isPluginEnabled("PlaceholderAPI")) {
            PlaceholderAPI.getPlaceholderPattern().matcher(this).matches()
        } else false
    }

interface PlaceholderHandler {
    fun onPlaceholderRequest(player: Player?, params: String): String?
}