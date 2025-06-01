package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player

@Entry(
    "integer_equal_audience",
    "Check if two integers are the same for a player",
    Colors.MEDIUM_SEA_GREEN,
    "typcn:equals"
)
/**
 * The `Integer Equal Audience` entry is an audience filter that checks if two variable integers are the same for each other.
 *
 * ## How could this be used?
 * Combined with the `Interaction Context Bounds Variable` you can check if the selected option of an `Option Dialogue` is selected.
 * Having things happening in the environment when the option is selected. Like a `Looping Cinematic` where particles are looped.
 */
class IntegerEqualAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    val left: Var<Int> = ConstVar(0),
    val right: Var<Int> = ConstVar(0),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter {
        return IntegerEqualAudience(ref(), left, right)
    }
}

class IntegerEqualAudience(
    ref: Ref<out AudienceFilterEntry>,
    val left: Var<Int>,
    val right: Var<Int>,
) : AudienceFilter(ref), TickableDisplay {
    override fun filter(player: Player): Boolean {
        return left.get(player) == right.get(player)
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
    }
}