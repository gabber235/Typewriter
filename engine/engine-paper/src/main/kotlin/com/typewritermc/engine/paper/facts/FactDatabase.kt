package com.typewritermc.engine.paper.facts

import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.ModifierOperator
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.ThreadType.DISPATCHERS_ASYNC
import com.typewritermc.engine.paper.utils.logErrorIfNull
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.concurrent.ConcurrentHashMap
import kotlin.collections.component1
import kotlin.collections.component2
import kotlin.collections.set

private const val FACT_STORAGE_DELAY = 60 * 3

class FactDatabase : KoinComponent {
    private val storage: FactStorage by inject()

    // Local stored version of player facts
    private val cache = ConcurrentHashMap<FactId, FactData>()

    fun initialize() {
        storage.init()

        // Load all the facts from the storage
        runBlocking {
            loadFactsFromPersistentStorage()
        }

        // Filter expired facts every second.
        // After that, save the facts of the players who have facts that expired or changed.
        DISPATCHERS_ASYNC.launch {
            var cycle = 1
            while (plugin.isEnabled) {
                delay(1000)
                removeExpiredFacts()

                if (cycle++ % FACT_STORAGE_DELAY == 0) {
                    storeFactsInPersistentStorage()
                }
            }
        }
    }

    fun shutdown() {
        runBlocking {
            storeFactsInPersistentStorage()
        }
        storage.shutdown()
    }

    private suspend fun loadFactsFromPersistentStorage() {
        val facts = storage.loadFacts()
        cache.clear()
        cache.putAll(facts)
    }

    private suspend fun storeFactsInPersistentStorage() {
        val entries =
            cache.keys.mapNotNull { Query.findById<PersistableFactEntry>(it.entryId) }.associateBy { it.id }

        // If there are no entries, we don't need to store anything.
        if (entries.isEmpty()) return

        val facts = cache.entries.filter { (id, data) ->
            val entry = entries[id.entryId] ?: return@filter false

            // If the fact is not persistable, or it has expired, don't store it.
            if (!entry.canPersist(id, data)) return@filter false
            if (entry is ExpirableFactEntry && entry.hasExpired(id, data)) return@filter false

            true
        }.map { (id, data) -> id to data }

        storage.storeFacts(facts)
    }

    private fun removeExpiredFacts() {
        val expiredIds = cache.entries.mapNotNull { (id, data) ->
            val entry = Query.findById<ExpirableFactEntry>(id.entryId) ?: return@mapNotNull null
            if (!entry.hasExpired(id, data)) return@mapNotNull null
            id
        }

        expiredIds.forEach { cache.remove(it) }
    }

    internal operator fun get(id: FactId): FactData? = cache[id]

    internal operator fun set(id: FactId, data: FactData) {
        if (data.value == 0) {
            cache.remove(id)
        } else {
            cache[id] = data
        }
    }

    fun modify(player: Player, modifiers: List<Modifier>) {
        modify(player) {
            modifiers.forEach { modifier ->
                this[modifier.fact] = when (modifier.operator) {
                    ModifierOperator.ADD -> {
                        val entry =
                            modifier.fact.get().logErrorIfNull("Could not find ${modifier.fact}") ?: return@forEach

                        if (entry !is ReadableFactEntry) {
                            plugin.logger.warning("Tried to add to a non-readable fact: ${modifier.fact}, how do you expect to add if you can't read?")
                            return@forEach
                        }

                        val fact = entry.readForPlayersGroup(player)
                        modifier.value.get(player) + fact.value
                    }
                    ModifierOperator.MULTIPLY -> {
                        val entry =
                            modifier.fact.get().logErrorIfNull("Could not find ${modifier.fact}") ?: return@forEach

                        if (entry !is ReadableFactEntry) {
                            plugin.logger.warning("Tried to multiply a non-readable fact: ${modifier.fact}, how do you expect to multiply if you can't read?")
                            return@forEach
                        }

                        val fact = entry.readForPlayersGroup(player)
                        modifier.value.get(player) * fact.value
                    }

                    ModifierOperator.SET -> modifier.value.get(player)
                }
            }
        }
    }

    fun modify(player: Player, modifier: FactsModifier.() -> Unit) {
        val modifications = FactsModifier().apply(modifier).build()
        if (modifications.isEmpty()) return

        for ((id, value) in modifications) {
            val entry = Query.findById<WritableFactEntry>(id) ?: continue
            entry.write(player, value)
            if (entry is ReadableFactEntry) {
                RefreshFactTrigger(entry.ref()).triggerFor(player, context())
            }
        }
    }
}

class FactsModifier {
    private val modifications = mutableMapOf<String, Int>()

    operator fun set(ref: Ref<out WritableFactEntry>, value: Int) = set(ref.id, value)

    operator fun set(id: String, value: Int) {
        modifications[id] = value
    }

    fun build(): Map<String, Int> = modifications
}

class RefreshFactTrigger(
    val fact: Ref<ReadableFactEntry>,
) : EventTrigger {
    override val id: String
        get() = "fact.${fact.id}"
}

fun Player.fact(ref: Ref<out ReadableFactEntry>) = ref.get()?.readForPlayersGroup(this)