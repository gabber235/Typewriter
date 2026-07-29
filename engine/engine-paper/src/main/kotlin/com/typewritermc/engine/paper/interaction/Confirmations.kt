package com.typewritermc.engine.paper.interaction

import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent.get
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Which key each player is being asked to press, and what picks that press up.
 *
 * Callers wait on a press with [await] instead of listening for a key themselves, so that the choice
 * of key is made in one place. Anything that takes a player's input away registers what is left of it
 * with [takeOver], so that choice can account for it.
 */
class Confirmations {
    private val inputs = ConcurrentHashMap<UUID, CopyOnWriteArrayList<ConfirmationInput>>()
    private val open = ConcurrentHashMap<UUID, CopyOnWriteArrayList<OpenConfirmation>>()

    /**
     * Registers [input] as what can be picked up from [player], until the registration is disposed.
     *
     * Registrations stack and the most recent one is in force, so a camera started inside another one
     * falls back to the outer one when it ends. Confirmations that are already waiting move over to
     * whichever one is in force, so one that started before the takeover is not left listening for a
     * key the player can no longer send.
     */
    fun takeOver(player: Player, input: ConfirmationInput): ConfirmationRegistration {
        require(input.available.isNotEmpty()) { "${input::class.simpleName} leaves no key to confirm with" }
        val id = player.uniqueId
        inputs.getOrPut(id) { CopyOnWriteArrayList() } += input
        rebind(player)
        return ConfirmationRegistration {
            inputs.computeIfPresent(id) { _, registered ->
                registered -= input
                registered.ifEmpty { null }
            }
            rebind(player)
        }
    }

    /**
     * Runs [onConfirm] every time [player] presses their confirmation key, until the returned
     * confirmation is disposed.
     *
     * [preferred] is used when the player's input can carry it, the configured [confirmationKey] when
     * it cannot, and whatever that input has left when it carries neither. That choice is made again
     * whenever the input in force changes, so [Confirmation.key] can change while the confirmation is
     * open.
     *
     * Confirmations stack the same way inputs do, and only the most recent one takes presses, so a
     * dialogue underneath a cinematic skip does not answer the press meant for the skip.
     */
    fun await(player: Player, preferred: ConfirmationKey? = null, onConfirm: () -> Unit): Confirmation {
        val id = player.uniqueId
        val input = inputFor(player)
        val confirmations = open.getOrPut(id) { CopyOnWriteArrayList() }

        val confirmation = OpenConfirmation(preferred, input.pick(preferred), confirmations, onConfirm) {
            confirmations -= it
            open.computeIfPresent(id) { _, remaining -> remaining.ifEmpty { null } }
        }
        confirmations += confirmation
        confirmation.bindTo(input)
        return confirmation
    }

    /**
     * The key [player] is being asked for right now, or null when nothing is waiting on a press.
     *
     * The most recent one wins, as it belongs to whatever was shown to them last.
     */
    fun keyOffered(player: Player): ConfirmationKey? = open[player.uniqueId]?.lastOrNull()?.key

    private fun rebind(player: Player) {
        val confirmations = open[player.uniqueId] ?: return
        val input = inputFor(player)
        confirmations.forEach { it.bindTo(input) }
    }

    private fun inputFor(player: Player): ConfirmationInput =
        inputs[player.uniqueId]?.lastOrNull() ?: BukkitConfirmationInput(player)
}

private fun ConfirmationInput.pick(preferred: ConfirmationKey?): ConfirmationKey {
    if (preferred != null && preferred in available) return preferred
    if (confirmationKey in available) return confirmationKey
    return available.first()
}

/**
 * A player being asked to press [key], for as long as it is not disposed.
 *
 * [key] follows whatever holds the player's input, so it can change while the confirmation is open.
 */
interface Confirmation : ConfirmationRegistration {
    val key: ConfirmationKey
}

private class OpenConfirmation(
    private val preferred: ConfirmationKey?,
    override var key: ConfirmationKey,
    private val siblings: List<OpenConfirmation>,
    private val onConfirm: () -> Unit,
    private val onDispose: (OpenConfirmation) -> Unit,
) : Confirmation {
    private var boundTo: ConfirmationInput? = null
    private val listening = AtomicReference<ConfirmationRegistration?>()
    private val disposed = AtomicBoolean(false)

    private val isDisposed: Boolean get() = disposed.get()

    /** Moves this over to [input], picking the key again out of what it can carry. */
    fun bindTo(input: ConfirmationInput) {
        if (isDisposed) return
        val key = input.pick(preferred)
        if (input === boundTo && key == this.key) return

        stopListening()
        boundTo = input
        this.key = key
        listening.set(input.listen(key, ::onPress))
        if (isDisposed) stopListening()
    }

    private fun onPress() {
        if (siblings.lastOrNull() !== this) return
        onConfirm()
    }

    private fun stopListening() {
        listening.getAndSet(null)?.dispose()
    }

    override fun dispose() {
        disposed.set(true)
        stopListening()
        onDispose(this)
    }
}

/**
 * Runs [onConfirm] every time this player presses their confirmation key.
 *
 * Dispose the confirmation when whatever was waiting on it is over.
 */
fun Player.awaitConfirmation(preferred: ConfirmationKey? = null, onConfirm: () -> Unit): Confirmation =
    get<Confirmations>(Confirmations::class.java).await(this, preferred, onConfirm)

/** Registers what can still be heard from this player, until the registration is disposed. */
fun Player.takeOverConfirmationInput(input: ConfirmationInput): ConfirmationRegistration =
    get<Confirmations>(Confirmations::class.java).takeOver(this, input)

/** The key this player is being asked for right now, or null when nothing is waiting on them. */
val Player.keyOffered: ConfirmationKey?
    get() = get<Confirmations>(Confirmations::class.java).keyOffered(this)
