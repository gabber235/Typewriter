package com.typewritermc.vault.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.ThreadType
import com.typewritermc.vault.VaultInitializer
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import com.typewritermc.core.utils.server
import net.milkbowl.vault.economy.Economy
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

@Entry(
    "balance_change_event",
    "Triggers when the player's balance changes",
    Colors.YELLOW,
    "fluent:wallet-credit-card-28-filled"
)
/**
 * The `Balance Change Event` entry is an event triggered when the player's balance changes.
 *
 * ## How could this be used?
 * This could be used to give the player a custom role when they reach a certain balance.
 * For example, they could be given the role of "Gold Member" when they reach 100$.
 */
class BalanceChangeEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : EventEntry

enum class BalanceChangeContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Double::class)
    PREVIOUS_BALANCE(Double::class),

    @KeyType(Double::class)
    NEW_BALANCE(Double::class),

    @KeyType(Int::class)
    PREVIOUS_AMOUNT(Int::class),

    @KeyType(Int::class)
    NEW_AMOUNT(Int::class),
}

@Singleton
class BalanceLoop : Initializable, Listener, KoinComponent {
    private var job: Job? = null
    private val vaultInitializer: VaultInitializer by inject()
    private val cachedBalance = ConcurrentHashMap<UUID, Double>()

    override suspend fun initialize() {
        val entries = Query.find<BalanceChangeEventEntry>().toList()
        if (entries.isEmpty()) return
        vaultInitializer.economy?.let {
            server.onlinePlayers.forEach { player ->
                val balance = it.getBalance(player)
                cachedBalance[player.uniqueId] = balance
            }
        }
        plugin.registerEvents(this)

        job = ThreadType.DISPATCHERS_ASYNC.launch {
            while (plugin.isEnabled) {
                delay(100)
                val economy = vaultInitializer.economy ?: continue
                server.onlinePlayers.forEach { player ->
                    player.checkBalance(economy, entries)
                }
            }
        }
    }

    private fun Player.checkBalance(
        economy: Economy,
        entries: List<BalanceChangeEventEntry>
    ) {
        val balance = economy.getBalance(this)
        val oldBalance = cachedBalance.getOrDefault(uniqueId, balance)
        if (balance == oldBalance) return

        cachedBalance[uniqueId] = balance
        entries.triggerAllFor(this) {
            BalanceChangeContextKeys.PREVIOUS_BALANCE withValue oldBalance
            BalanceChangeContextKeys.NEW_BALANCE withValue balance
            BalanceChangeContextKeys.PREVIOUS_AMOUNT withValue oldBalance.toInt()
            BalanceChangeContextKeys.NEW_AMOUNT withValue balance.toInt()
        }
    }

    @EventHandler
    private fun onPlayerJoin(event: PlayerJoinEvent) {
        val player = event.player
        val economy = vaultInitializer.economy ?: return
        val balance = economy.getBalance(player)
        cachedBalance[player.uniqueId] = balance
    }

    @EventHandler
    private fun onPlayerQuit(event: PlayerJoinEvent) {
        val player = event.player
        cachedBalance.remove(player.uniqueId)
    }

    override suspend fun shutdown() {
        unregister()
        job?.cancel()
        job = null
        cachedBalance.clear()
    }

}