package com.typewritermc.identity

/**
 * Something Typewriter tracks across engines by a stable id: values keyed by an identity end when it ends.
 */
sealed interface Identity

/**
 * Who an identity acts for: a Minecraft player is `PrincipalId("minecraft", <uuid>)`, a panel user
 * `PrincipalId("user", <user id>)`.
 */
data class PrincipalId(
    val kind: String,
    val id: String,
) {
    init {
        require(kind.isNotBlank()) { "A principal kind is not blank." }
        require(id.isNotBlank()) { "A principal id is not blank." }
    }

    override fun toString(): String = "$kind:$id"

    companion object {
        /** The kind of a Minecraft player, whose id is the player's UUID. */
        const val MINECRAFT: String = "minecraft"

        /** The kind of a panel user, whose id is the Typewriter user id. */
        const val USER: String = "user"
    }
}

/** The one actor a protagonist is, across every engine and connection it has. */
data class Protagonist(
    val principal: PrincipalId,
) : Identity

/**
 * One engine of a Realm: the topology engine instance id, `panel.<realm id>` for the Realm's panel engine, or
 * `local.<realm id>` for an engine of a host running without topology. It survives restarts and ends when the engine
 * leaves the topology. Engine ids order by their text, so two engines claiming a session at the same instant agree on
 * which one holds it.
 */
@JvmInline
value class EngineId(
    val value: String,
) : Comparable<EngineId> {
    init {
        require(value.isNotBlank()) { "An engine id is not blank." }
    }

    override fun compareTo(other: EngineId): Int = value.compareTo(other.value)

    override fun toString(): String = value
}

/** One engine as an identity. */
data class Engine(
    val id: EngineId,
) : Identity

/**
 * One connection of a protagonist, chosen by its engine kind: the player UUID for Minecraft, which survives server
 * moves, or a per tab id for the panel, which survives reloads.
 */
@JvmInline
value class SessionId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "A session id is not blank." }
    }

    override fun toString(): String = value
}

/** One connection of a protagonist as an identity. A protagonist is online while it has at least one. */
data class Session(
    val protagonist: Protagonist,
    val id: SessionId,
) : Identity
