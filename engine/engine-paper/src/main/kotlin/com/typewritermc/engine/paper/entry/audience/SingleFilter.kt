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

/**
 * Filters and displays at most one display entry type to the player.
 * This is useful for displaying a single sidebar, or a tab list header/footer.
 */
abstract class SingleFilter<E : AudienceFilterEntry, D : PlayerSingleDisplay<E>>(
    internal val ref: Ref<E>,
    private val createDisplay: (Player) -> D
) : AudienceFilter(ref), TickableDisplay {
    // Map needs to be shared between all instances of the display
    protected abstract val displays: MutableMap<UUID, D>

    override fun filter(player: Player): Boolean = displays[player.uniqueId]?.ref == ref
    override fun tick() {
        displays.values.filter { it.ref == ref }.forEach { it.tick() }
    }

    override fun onPlayerAdd(player: Player) {
        displays.computeIfAbsent(player.uniqueId)
        {
            createDisplay(player)
                .also { it.initialize() }
        }
            .onAddedBy(ref)
        super.onPlayerAdd(player)
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        displays.computeIfPresent(player.uniqueId) { _, display ->
            if (display.onRemovedBy(ref)) {
                display.dispose()
                null
            } else {
                display
            }
        }
    }
}

abstract class PlayerSingleDisplay<E : AudienceFilterEntry>(
    protected val player: Player,
    private val displayKClass: KClass<out SingleFilter<E, *>>,
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