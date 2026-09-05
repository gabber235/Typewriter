package com.typewritermc.region.entries.audience

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.handler.RegionHandler
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * Shared base for region based [AudienceFilter]s. It observes the [RegionEngine] when a
 * player is added, cancels the subscription when they are removed, and drains everything on
 * dispose. Concrete filters only decide which [RegionHandler] to attach and what the filter
 * returns for a player.
 */
abstract class RegionAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    protected val region: RegionData,
) : AudienceFilter(ref) {
    protected val engine: RegionEngine by lazy {
        KoinJavaComponent.get(RegionEngine::class.java)
    }
    private val subs = ConcurrentHashMap<UUID, RegionEngine.Subscription>()

    /**
     * The handler kind this filter attaches for [player]. Called once per player when
     * they enter the filter's audience. Implementations typically build an [EnterExitHandler][com.typewritermc.region.handler.EnterExitHandler]
     * or a [ProximityHandler][com.typewritermc.region.handler.ProximityHandler] and have it
     * call [player.refresh][AudienceFilter.refresh] on transition.
     */
    protected abstract fun createHandler(player: Player): RegionHandler

    override fun onPlayerAdd(player: Player) {
        super.onPlayerAdd(player)
        engine.observe(region, player, createHandler(player))?.also { subs[player.uniqueId] = it }
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        subs.remove(player.uniqueId)?.cancel()
    }

    override fun dispose() {
        subs.values.forEach(RegionEngine.Subscription::cancel)
        subs.clear()
        super.dispose()
    }
}
