package com.typewritermc.example.entries.manifest

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.PriorityEntry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.audience.PlayerSingleDisplay
import com.typewritermc.engine.paper.entry.audience.SingleFilter
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

//<code-block:single_filter_basic>
@Entry("example_single_filter", "An example single filter entry", Colors.MYRTLE_GREEN, "material-symbols:filter-alt")
class ExampleSingleFilterEntry(
    override val id: String = "",
    override val name: String = "",
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : AudienceFilterEntry, PriorityEntry {
    override val children: List<Ref<out AudienceEntry>> get() = emptyList()

    override suspend fun display(): AudienceFilter = ExampleSingleFilter(ref()) { player ->
        PlayerExampleDisplay(player, ExampleSingleFilter::class, ref())
    }
}

private class ExampleSingleFilter(
    ref: Ref<ExampleSingleFilterEntry>,
    createDisplay: (Player) -> PlayerExampleDisplay,
) : SingleFilter<ExampleSingleFilterEntry, PlayerExampleDisplay>(ref, createDisplay) {
    // highlight-start
    // This must be a references to a shared map.
    // It CANNOT cache the map itself.
    override val displays: MutableMap<UUID, PlayerExampleDisplay>
        get() = map
    // highlight-end

    // highlight-start
    companion object {
        // This map is shared between all instances of the filter.
        private val map = ConcurrentHashMap<UUID, PlayerExampleDisplay>()
    }
    // highlight-end
}

private class PlayerExampleDisplay(
    player: Player,
    displayKClass: KClass<out SingleFilter<ExampleSingleFilterEntry, *>>,
    current: Ref<ExampleSingleFilterEntry>
) : PlayerSingleDisplay<ExampleSingleFilterEntry>(player, displayKClass, current) {
    override fun setup() {
        super.setup()
        player.sendMessage("Display activated!")
    }

    override fun tearDown() {
        super.tearDown()
        player.sendMessage("Display deactivated!")
    }
}
//</code-block:single_filter_basic>

//<code-block:single_filter_lifecycle>
private class ComplexPlayerDisplay(
    player: Player,
    displayKClass: KClass<out SingleFilter<ExampleSingleFilterEntry, *>>,
    current: Ref<ExampleSingleFilterEntry>
) : PlayerSingleDisplay<ExampleSingleFilterEntry>(player, displayKClass, current) {
    override fun initialize() {
        super.initialize()
        // Called once when the display is first created
        player.sendMessage("Display initialized!")
    }

    override fun setup() {
        super.setup()
        // Called every time this display becomes active
        player.sendMessage("Display setup!")
    }

    override fun tick() {
        // Called every tick while the display is active
        // Update display content here
    }

    override fun tearDown() {
        super.tearDown()
        // Called when this display becomes inactive
        player.sendMessage("Display torn down!")
    }

    override fun dispose() {
        super.dispose()
        // Called when the display is being completely removed
        player.sendMessage("Display disposed!")
    }
}
