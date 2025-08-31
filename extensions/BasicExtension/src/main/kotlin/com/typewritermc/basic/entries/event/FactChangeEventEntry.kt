package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.CriteriaOperator
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.facts.FactListenerSubscription
import com.typewritermc.engine.paper.facts.listenForFacts
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.server
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass
import kotlin.time.Duration.Companion.seconds

@Entry(
    "fact_change_event",
    "Triggers when the specified fact changes",
    Colors.YELLOW,
    "material-symbols:change-circle-rounded"
)
@ContextKeys(FactChangeContextKeys::class)
/**
 * The `Fact Change Event` is triggered when the specified fact changes.
 *
 * ## How could this be used?
 * When things without a clear event but with a fact change values.
 */
class FactChangeEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val fact: Ref<ReadableFactEntry> = emptyRef(),
    val previousValueCriteria: List<FactCriteria> = emptyList(),
    val newValueCriteria: List<FactCriteria> = emptyList(),
) : EventEntry

data class FactCriteria(
    val operator: CriteriaOperator = CriteriaOperator.EQUALS,
    val value: Var<Int> = ConstVar(0)
) {
    fun matches(player: Player, context: InteractionContext?, value: Int): Boolean {
        return this.value.get(player, context) == value
    }
}

fun List<FactCriteria>.matches(player: Player, context: InteractionContext?, value: Int): Boolean {
    return this.all { it.matches(player, context, value) }
}

enum class FactChangeContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Int::class)
    PREVIOUS_VALUE(Int::class),

    @KeyType(Int::class)
    NEW_VALUE(Int::class),
}

@Singleton
class FactEventWatcher : Initializable, Listener {
    private val subscriptions = ConcurrentHashMap<UUID, FactListenerSubscription>()
    private var facts = emptyList<Ref<ReadableFactEntry>>()

    override suspend fun initialize() {
        facts = Query.find<FactChangeEventEntry>().map { it.fact }.distinct().toList()
        Dispatchers.UntickedAsync.launch {
            delay(1.seconds)
            server.onlinePlayers.forEach { it.watch() }
        }
    }

    fun Player.watch() {
        subscriptions[uniqueId] = listenForFacts(facts) {
            Query.findWhere<FactChangeEventEntry> {
                it.fact == ref &&
                        it.previousValueCriteria.matches(player, player.interactionContext, oldValue) &&
                        it.newValueCriteria.matches(player, player.interactionContext, newValue)
            }.triggerAllFor(this@watch) {
                FactChangeContextKeys.PREVIOUS_VALUE += oldValue
                FactChangeContextKeys.NEW_VALUE += newValue
            }
        }
    }

    @EventHandler
    fun onJoin(event: PlayerJoinEvent) = event.player.watch()

    @EventHandler
    fun onQuit(event: PlayerQuitEvent) {
        subscriptions.remove(event.player.uniqueId)?.cancel(event.player)
    }

    override suspend fun shutdown() {
        subscriptions.forEach { (pid, subscription) ->
            val player = server.getPlayer(pid) ?: return@forEach
            subscription.cancel(player)
        }
        subscriptions.clear()
    }
}
