package com.typewritermc.region.flag

import com.typewritermc.core.utils.point.Position
import com.typewritermc.region.entries.modifier.BlockBreakModifierEntry
import com.typewritermc.region.entries.modifier.BlockInteractModifierEntry
import com.typewritermc.region.entries.modifier.BlockPlaceModifierEntry
import com.typewritermc.region.entries.modifier.BucketModifierEntry
import com.typewritermc.region.entries.modifier.EntityDamageModifierEntry
import com.typewritermc.region.entries.modifier.EntityInteractModifierEntry
import com.typewritermc.region.entries.modifier.ExplosionModifierEntry
import com.typewritermc.region.entries.modifier.FireSpreadModifierEntry
import com.typewritermc.region.entries.modifier.FluidFlowModifierEntry
import com.typewritermc.region.entries.modifier.IgniteModifierEntry
import com.typewritermc.region.entries.modifier.MobDamageModifierEntry
import com.typewritermc.region.entries.modifier.MobGriefModifierEntry
import com.typewritermc.region.entries.modifier.MobSpawnModifierEntry
import com.typewritermc.region.entries.modifier.PistonModifierEntry
import com.typewritermc.region.entries.modifier.PlayerDamageModifierEntry
import com.typewritermc.region.entries.modifier.PvpModifierEntry
import com.typewritermc.region.entries.modifier.RedstoneModifierEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.entries.modifier.TrampleModifierEntry
import org.bukkit.entity.Player
import kotlin.reflect.KClass

/** A short, human readable name per flag type, matched one for one against [handlerFactories]. */
internal val FLAG_LABELS: Map<KClass<out RegionModifierEntry>, String> = mapOf(
    BlockBreakModifierEntry::class to "Block Break",
    BlockPlaceModifierEntry::class to "Block Place",
    BlockInteractModifierEntry::class to "Block Interact",
    EntityInteractModifierEntry::class to "Entity Interact",
    BucketModifierEntry::class to "Bucket",
    PistonModifierEntry::class to "Piston",
    RedstoneModifierEntry::class to "Redstone",
    FireSpreadModifierEntry::class to "Fire Spread",
    FluidFlowModifierEntry::class to "Fluid Flow",
    ExplosionModifierEntry::class to "Explosion",
    MobSpawnModifierEntry::class to "Mob Spawn",
    MobGriefModifierEntry::class to "Mob Grief",
    PvpModifierEntry::class to "PvP",
    MobDamageModifierEntry::class to "Mob Damage",
    PlayerDamageModifierEntry::class to "Player Damage",
    EntityDamageModifierEntry::class to "Entity Damage",
    TrampleModifierEntry::class to "Trample",
    IgniteModifierEntry::class to "Ignite",
)

private fun RegionModifierEntry.label(): String =
    FLAG_LABELS[this::class] ?: error("FlagReport has no label for ${this::class.simpleName}")

private fun RegionModifierEntry.isAllowed(player: Player): Boolean = when (this) {
    is BlockBreakModifierEntry -> allowed.get(player)
    is BlockPlaceModifierEntry -> allowed.get(player)
    is BlockInteractModifierEntry -> allowed.get(player)
    is EntityInteractModifierEntry -> allowed.get(player)
    is BucketModifierEntry -> allowed.get(player)
    is EntityDamageModifierEntry -> allowed.get(player)
    is TrampleModifierEntry -> allowed.get(player)
    is IgniteModifierEntry -> allowed.get(player)
    is PvpModifierEntry -> allowed.get(player)
    is MobDamageModifierEntry -> allowed.get(player)
    is PlayerDamageModifierEntry -> allowed.get(player)
    is PistonModifierEntry -> allowed
    is RedstoneModifierEntry -> allowed
    is FireSpreadModifierEntry -> allowed
    is FluidFlowModifierEntry -> allowed
    is ExplosionModifierEntry -> allowed
    is MobSpawnModifierEntry -> allowed
    is MobGriefModifierEntry -> allowed
    else -> error("FlagReport does not know how to read the value of ${this::class.simpleName}")
}

private fun Boolean.asChatValue(): String = if (this) "<green>✔ allowed</green>" else "<red>✘ denied</red>"

private fun Boolean.asChatMark(): String = if (this) "<green>✔</green>" else "<red>✘</red>"

/**
 * Every flagged region containing [position], highest priority first, one line per region
 * with the flags it carries inline. This is "what am I standing in": every region's own
 * opinion, not just the one that wins.
 */
internal fun standingReport(index: RegionFlagIndex, position: Position, player: Player): List<String> {
    val regions = index.regionsAt(position, player)
    if (regions.isEmpty()) return listOf("<gray>No flagged region contains this position.")

    return regions.map { region ->
        val flags = region.modifiers.values.joinToString("<dark_gray> · </dark_gray>") { flag ->
            val scope = flag.causeScope()
            val scoped = if (scope == null) "" else "<dark_gray>($scope)</dark_gray>"
            "<white>${flag.label()}</white>$scoped ${flag.isAllowed(player).asChatMark()}"
        }.ifEmpty { "<dark_gray>no flags" }
        "<blue>${region.entry.name}</blue> <dark_gray>(priority ${region.priority})</dark_gray> $flags"
    }
}

/**
 * The flags actually in force at [position]: one line per decided flag with its value, the
 * deciding region and its priority. Flags no region decides collapse into one trailing
 * counter whose names sit on its hover, so the answer is not buried in noise. This is
 * "what am I looking at": the winner only, never every region's opinion.
 */
internal fun flagReport(index: RegionFlagIndex, position: Position, player: Player): List<String> {
    val decided = mutableListOf<String>()
    val undecided = mutableListOf<String>()
    for (type in handlerFactories.keys) {
        val label = FLAG_LABELS[type] ?: error("FlagReport has no label for ${type.simpleName}")
        val lines = decisionLines(index, type, label, position, player)
        if (lines.isEmpty()) undecided += label else decided += lines
    }
    if (decided.isEmpty()) return listOf("<gray>No region decides any flag at this block.")
    if (undecided.isNotEmpty()) {
        val names = undecided.joinToString(", ")
        decided += "<dark_gray><hover:show_text:'$names'>+ ${undecided.size} undecided " +
                "flag${if (undecided.size == 1) "" else "s"}</hover>"
    }
    return decided
}

private fun <M : RegionModifierEntry> decisionLines(
    index: RegionFlagIndex,
    type: KClass<M>,
    label: String,
    position: Position,
    player: Player,
): List<String> {
    val decision = index.resolveDecision(type, position, player) ?: return emptyList()
    val winner = decisionLine(decision, label, decision.flag.causeScope(), player)
    if (decision.flag.causeScope() == null) return listOf(winner)

    // A Player Damage flag that names its causes decides about those and abstains from the rest,
    // so the winner is not the whole answer. Whatever blanket flag sits below it is what a builder
    // needs when they ask why damage still gets through, and stopping at the winner hides it.
    val blanket = index.resolveDecision(PlayerDamageModifierEntry::class, position, player) {
        it.causes.isEmpty()
    } ?: return listOf(winner)
    return listOf(winner, decisionLine(blanket, label, "every other cause", player))
}

private fun decisionLine(
    decision: FlagDecision<out RegionModifierEntry>,
    label: String,
    scope: String?,
    player: Player,
): String {
    val value = decision.flag.isAllowed(player).asChatValue()
    val scoped = if (scope == null) "" else " <dark_gray>for <white>$scope</white></dark_gray>"
    return "<white>$label</white> $value$scoped <dark_gray>← <blue>${decision.regionName}</blue> priority ${decision.priority}</dark_gray>"
}

/** The causes a flag limits itself to, or `null` when it decides about all of them. */
private fun RegionModifierEntry.causeScope(): String? = (this as? PlayerDamageModifierEntry)?.causes
    ?.takeIf { it.isNotEmpty() }
    ?.joinToString(", ") { it.name.lowercase() }
