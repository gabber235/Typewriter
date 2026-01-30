package com.typewritermc.basic.entries.static.factspreset

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.StaticEntry
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.WritableFactEntry
import com.typewritermc.engine.paper.entry.eventTriggers
import com.typewritermc.engine.paper.facts.FactsModifier
import com.typewritermc.engine.paper.plugin
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import org.bukkit.entity.Player
import org.bukkit.event.Listener

@Tags("facts_preset")
interface FactsPresetEntry : StaticEntry {
    val children: List<Ref<FactsPresetEntry>>
    val presets: List<FactPreset>
    val triggers: List<Ref<TriggerableEntry>>

    fun applier(player: Player, modifier: FactsModifier, serializer: FactsPresetSerializer): FactsPresetApplier<*>
}

data class FactPreset(
    val ref: Ref<WritableFactEntry> = emptyRef(),
    val value: Var<Int> = ConstVar(0),
)

fun FactsModifier.apply(player: Player, list: List<FactPreset>) {
    for (entry in list) {
        this[entry.ref] = entry.value.get(player)
    }
}

enum class FactsPresetApplierState {
    RUNNING,
    FINISHED,
    CANCELLED,
}

open class FactsPresetApplier<FPE : FactsPresetEntry>(
    val player: Player,
    val entry: FPE,
    val modifier: FactsModifier,
    val serializer: FactsPresetSerializer,
) : Listener {
    open var state: FactsPresetApplierState = FactsPresetApplierState.RUNNING
        protected set

    open val appliedChildren get() = entry.children

    open val appliedTriggers: List<EventTrigger>
        get() = entry.triggers.eventTriggers

    open fun init() {
        plugin.registerEvents(this)
    }

    open fun tick(context: TickContext) {}

    open fun dispose() {
        unregister()
    }
}