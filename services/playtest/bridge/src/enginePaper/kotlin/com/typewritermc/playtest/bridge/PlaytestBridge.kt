package com.typewritermc.playtest.bridge

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.events.ChainQueue
import com.typewritermc.engine.events.SubjectWork
import com.typewritermc.engine.paper.PaperEvents
import com.typewritermc.engine.paper.PaperProtagonists
import com.typewritermc.engine.paper.protagonist
import com.typewritermc.engine.runtime.PublicationObserver
import com.typewritermc.events.EnginePart
import com.typewritermc.identity.Protagonist
import com.typewritermc.playtest.plugin.AppliedContent
import com.typewritermc.playtest.plugin.PlayerWipeEvent
import com.typewritermc.playtest.plugin.PlayerWork
import com.typewritermc.types.ResourceId
import org.bukkit.plugin.Plugin
import org.bukkit.plugin.ServicePriority
import skirout.editor.v1.type_catalog.PublicationId

/**
 * Counts each chain of a Minecraft protagonist as work of its online player, so a stepped Paper waits until the
 * player's reaction is done. A queued chain starts only when a tick's end picks it up, so it is scheduled work: the
 * next tick starts, and the one after waits for the chain. A protagonist with no online player here counts nothing.
 */
class PlayerChainWork(
    plugin: Plugin,
) : SubjectWork {
    private val players = PaperProtagonists(plugin)

    override fun begin(
        protagonist: Protagonist,
        name: String,
    ): AutoCloseable = players.live(protagonist)?.let { PlayerWork.scheduled(it.player, name) } ?: AutoCloseable {}
}

/** Drops every waiting chain of a player Paper wipes for a new attempt, so no chain of one attempt reaches the next. */
class WipeDropsChains(
    private val events: PaperEvents,
    private val chains: ChainQueue,
) : EnginePart,
    RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        scope.own(events.listen(PlayerWipeEvent::class) { chains.clear(it.player.protagonist) })
    }
}

/**
 * Keeps the publication this engine applied last, with its roots, and offers it to the Playtest plugin as its
 * [AppliedContent] service while the engine runs, so a game requirement waits until its content is live here.
 *
 * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
 */
class AppliedRoots(
    private val plugin: Plugin,
) : PublicationObserver,
    AppliedContent,
    RuntimeRegistrar {
    /** The last applied publication's id and roots, replaced together. */
    @Volatile
    private var last: Pair<String?, Set<String>> = null to emptySet()

    override fun applied(
        publication: PublicationId,
        resources: Set<ResourceId>,
    ) {
        last = publication.value to resources.mapTo(linkedSetOf()) { it.value }
    }

    override fun applied(): Set<String> = last.second

    override fun publication(): String? = last.first

    context(scope: RuntimeScope)
    override suspend fun register() {
        val services = plugin.server.servicesManager
        services.register(AppliedContent::class.java, this, plugin, ServicePriority.Normal)
        scope.own { services.unregister(AppliedContent::class.java, this) }
    }
}
