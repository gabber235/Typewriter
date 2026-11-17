package com.typewritermc.engine.paper.entry.audience

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.*
import kotlin.reflect.KClass

abstract class SingleKeyedFilter<E : AudienceFilterEntry, K, D : PlayerSingleKeyedDisplay<E, K>>(
    internal val ref: Ref<E>,
    private val createDisplay: (Player) -> D,
) : AudienceFilter(ref), TickableDisplay {
    protected abstract val displays: MutableMap<MultiKey<UUID, K>, D>
    private val previousKeys = mutableMapOf<UUID, K>()

    abstract fun key(player: Player): K

    override fun filter(player: Player): Boolean {
        val key = previousKeys.computeIfAbsent(player.uniqueId) { key(player) }
        return displays[player.uniqueId, key]?.ref == ref
    }

    private fun addPlayerToDisplay(player: Player, key: K) {
        displays.computeIfAbsent(MultiKey(player.uniqueId, key)) {
            createDisplay(player)
                .also { it.initialize() }
        }
            .onAddedBy(ref)
    }

    private fun removePlayerFromDisplay(player: Player, key: K) {
        displays.computeIfPresent(MultiKey(player.uniqueId, key)) { _, display ->
            if (display.onRemovedBy(ref)) {
                display.dispose()
                null
            } else {
                display
            }
        }
    }

    override fun onPlayerAdd(player: Player) {
        val key = key(player)
        previousKeys[player.uniqueId] = key
        addPlayerToDisplay(player, key)
        super.onPlayerAdd(player)
    }

    override fun tick() {
        consideredPlayers.forEach { player ->
            val oldKey = previousKeys[player.uniqueId] ?: return@forEach
            val newKey = key(player)
            previousKeys[player.uniqueId] = newKey
            if (oldKey == newKey) return@forEach
            removePlayerFromDisplay(player, oldKey)
            addPlayerToDisplay(player, newKey)
        }

        displays.values.filter { it.ref == ref }.forEach { it.tick() }
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        val key = previousKeys.remove(player.uniqueId) ?: key(player)
        removePlayerFromDisplay(player, key)
    }

    internal fun cachedKey(player: Player): K? {
        return previousKeys[player.uniqueId]
    }
}

abstract class PlayerSingleKeyedDisplay<E : AudienceFilterEntry, K>(
    protected val player: Player,
    private val key: K,
    private val displayKClass: KClass<out SingleKeyedFilter<E, K, *>>,
    @Volatile private var current: Ref<E>,
) : KoinComponent {
    private val audienceManager: AudienceManager by inject()
    val ref: Ref<E> get() = current

    /**
     * Called when the player is added to a display for the first time
     */
    open fun initialize() {
        setup()
    }

    /**
     * Called everytime the player is added to a display.
     * Either after [initialize] or when the display changed for the player
     */
    open fun setup() {
        val filter = audienceManager[ref] as? AudienceFilter? ?: return
        with(filter) {
            player.updateFilter(true)
        }
    }

    /**
     * Called every tick
     */
    open fun tick() {}

    /**
     * Called when the player is removed from a display
     */
    open fun tearDown() {
        val filter = audienceManager[ref] as? AudienceFilter? ?: return
        with(filter) {
            player.updateFilter(false)
        }
    }

    /**
     * Called when the player is no longer in any display
     */
    open fun dispose() {
        tearDown()
    }

    fun onAddedBy(ref: Ref<E>): Boolean {
        if (current.priority > ref.priority) return false
        if (ref == current) return false
        tearDown()
        current = ref
        setup()
        return true
    }

    /**
     * @return true if the display should be removed
     */
    fun onRemovedBy(ref: Ref<E>): Boolean {
        if (current != ref) return false
        val new = audienceManager.findDisplays(displayKClass)
            .filter { it.canConsider(player) }
            .filter { it.cachedKey(player) == key }
            .maxByOrNull { it.ref.priority }
        if (new == null) {
            return true
        }
        tearDown()
        current = new.ref
        setup()
        return false
    }
}

data class MultiKey<K1, K2>(
    val key1: K1,
    val key2: K2,
) {
    override fun toString(): String {
        return "[$key1, $key2]"
    }
}

operator fun <K1, K2, V> Map<MultiKey<K1, K2>, V>.get(key: K1, key2: K2): V? {
    return get(MultiKey(key, key2))
}