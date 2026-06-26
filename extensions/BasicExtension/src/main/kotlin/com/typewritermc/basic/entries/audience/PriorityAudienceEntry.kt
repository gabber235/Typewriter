package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.audience.MultiKey
import com.typewritermc.engine.paper.entry.audience.PlayerSingleKeyedDisplay
import com.typewritermc.engine.paper.entry.audience.SingleKeyedFilter
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

@Entry(
    "priority_audience",
    "Priority Audience",
    Colors.MEDIUM_SEA_GREEN,
    "material-symbols:priority-high-rounded"
)
/**
 * The `Priority Audience` entry is a keyed priority gate for child audiences.
 *
 * Entries that resolve to the same `tag` compete with each other, and only the highest-priority
 * entry is considered active for that player and tag. Entries with different tags do not compete.
 *
 * This entry does not add gameplay effects by itself. It is meant to group children and enforce
 * "only one active at a time" behavior per tag.
 *
 * ## How could this be used?
 * Use the same tag across multiple conditional audience branches and let entry priority decide
 * which branch is active when several match at once.
 */
class PriorityAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    @Default("\"default\"")
    val tag: Var<String> = ConstVar("default"),
) : AudienceFilterEntry {

    override suspend fun display(): AudienceFilter {
        return PriorityAudience(tag, ref()) { player ->
            PriorityAudienceDisplay(player, tag.get(player), PriorityAudience::class, ref())
        }
    }
}

class PriorityAudience(
    private val tag: Var<String>,
    ref: Ref<PriorityAudienceEntry>,
    createDisplay: (Player) -> PriorityAudienceDisplay,
) : SingleKeyedFilter<PriorityAudienceEntry, String, PriorityAudienceDisplay>(ref, createDisplay) {
    override val displays: MutableMap<MultiKey<UUID, String>, PriorityAudienceDisplay>
        get() = map

    override fun key(player: Player): String {
        return tag.get(player)
    }

    companion object {
        private val map = ConcurrentHashMap<MultiKey<UUID, String>, PriorityAudienceDisplay>()
    }
}

class PriorityAudienceDisplay(
    player: Player,
    tag: String,
    displayKClass: KClass<out SingleKeyedFilter<PriorityAudienceEntry, String, *>>,
    current: Ref<PriorityAudienceEntry>,
) : PlayerSingleKeyedDisplay<PriorityAudienceEntry, String>(player, tag, displayKClass, current)
