package com.typewritermc.basic.entries.static.factspreset

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.ref
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.ok
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.facts.FactDatabase
import com.typewritermc.engine.paper.facts.FactsModifier
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.msg
import net.kyori.adventure.key.Key
import net.kyori.adventure.sound.Sound
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.time.Duration
import java.util.Locale.getDefault

class FactsPresetInteraction(
    private val player: Player,
    override val context: InteractionContext,
    private val ref: Ref<FactsPresetEntry>,
    givenTriggers: List<EventTrigger>,
    private val serialized: String,
) : Interaction, KoinComponent {
    private val factDatabase: FactDatabase by inject()

    override val priority: Int
        get() = ref.priority

    private val modifier = FactsModifier()

    private val processingOrder: MutableList<Ref<FactsPresetEntry>> = mutableListOf()
    private val children: MutableMap<Ref<FactsPresetEntry>, List<FactsPresetEntry>> = mutableMapOf()
    private val unAppliedParents: MutableMap<Ref<FactsPresetEntry>, Set<FactsPresetEntry>> = mutableMapOf()

    private var applier: FactsPresetApplier<*>? = null
    private var playTime = Duration.ZERO
    var eventTriggers = givenTriggers
        private set

    private val serializer = FactsPresetSerializer(serialized)

    init {
        assert(ref.isSet) { "The Ref to the FactsPreset must be set." }
    }

    override suspend fun initialize(): Result<Unit> {
        val todo = mutableListOf(ref)

        while (todo.isNotEmpty()) {
            val ref = todo.removeFirst()
            /// If we already visited this ref, we don't need to visit it again
            if (children.containsKey(ref)) continue
            val entry = ref.get() ?: continue
            val children = entry.children.mapNotNull { it.get() }
            this.children[ref] = children
            this.processingOrder.add(ref)

            unAppliedParents.putIfAbsent(ref, emptySet())
            for (child in children) {
                unAppliedParents.compute(child.ref()) { _, set ->
                    if (set != null) set + entry
                    else setOf(entry)
                }
            }

            entry.children.reversed().forEach { todo.addFirst(it) }
        }

        processingOrder.sortBy { it.priority }

        nextApplier()

        return ok(Unit)
    }

    fun nextApplier(): Boolean {
        val current = applier?.entry
        if (current != null) {
            eventTriggers += applier?.appliedTriggers ?: emptyList()
            applier?.appliedChildren?.forEach { childRef -> unAppliedParents.computeIfPresent(childRef) { _, parents -> (parents - current) } }
        }
        applier?.dispose()
        applier = null

        val ref = processingOrder.firstOrNull { unAppliedParents[it]!!.isEmpty() } ?: return false
        require(ref.isSet) { "We only add to the unapplied parents if there is a reference" }

        processingOrder.remove(ref)
        unAppliedParents.remove(ref)

        val entry = ref.get()
        require(entry != null) { "We only add an entry that exists." }

        applier = entry.applier(player, modifier, serializer)
        applier!!.init()

        // If we finish immediately, we can shortcut to the next applier to have them all run quickly in one tick
        if (applier!!.state == FactsPresetApplierState.FINISHED) {
            return nextApplier()
        }

        return true
    }

    override suspend fun tick(deltaTime: Duration) {
        playTime += deltaTime
        val applier = applier

        if (applier == null) {
            end()
        } else if (applier.state == FactsPresetApplierState.FINISHED) {
            nextApplier()
        } else if (applier.state == FactsPresetApplierState.CANCELLED) {
            InteractionEndTrigger.triggerFor(player, context)
        } else {
            applier.tick(TickContext(playTime, deltaTime))
        }
    }

    private fun end() {
        val serialization = serializer.toString()
        if (serialization.isNotEmpty() && this.serialized != serialization) {
            val command = "/tw facts preset apply ${ref.get()!!.name} \"$serialization\""
            player.msg("To reapply this preset run: <i><blue><click:suggest_command:'$command'>$command</click>")
        }
        player.sendActionBar("Applied <red>${ref.get()!!.name}</red> preset".asMini())
        player.playSound(Sound.sound().type(Key.key("entity.experience_orb.pickup")).build())

        factDatabase.modify(player, modifier.build())
        FactsPresetStopTrigger.triggerFor(player, context)
    }

    override suspend fun teardown() {
        applier?.dispose()
        applier = null
    }
}

class FactsPresetSerializer(
    providedSerialization: String,
) {
    private val deserialized = providedSerialization.split("|").toMutableList()
    private val serialized = mutableListOf<String>()

    fun peek() = deserialized.firstOrNull()
    fun pop(): String? {
        if (deserialized.isEmpty()) return null
        return deserialized.removeFirst()
    }

    fun push(value: String): Boolean {
        if (value.isEmpty()) return false
        val serialized = value.replace(Regex("[| ]"), ",").lowercase(getDefault())
        return this.serialized.add(serialized)
    }

    override fun toString() = serialized.joinToString("|")
}