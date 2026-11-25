package com.typewritermc.engine.session

import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.LeaseCodec
import com.typewritermc.services.libs.communicator.kv.LeaseEntry
import com.typewritermc.services.libs.communicator.kv.LeaseState
import okio.ByteString.Companion.toByteString
import java.io.IOException
import java.time.Instant
import java.util.logging.Logger
import skirout.service.v1.session.EngineId as WireEngineId
import skirout.service.v1.session.PrincipalId as WirePrincipalId
import skirout.service.v1.session.Protagonist as WireProtagonist
import skirout.service.v1.session.SessionEntry as WireSessionEntry
import skirout.service.v1.session.SessionHold as WireSessionHold
import skirout.service.v1.session.SessionState as WireSessionState

/** One session's entry in the Realm's sessions bucket: who it belongs to, since when it runs, and who holds it. */
data class SessionEntry(
    val protagonist: Protagonist,
    val since: Instant,
    val state: SessionState,
) {
    /** The engine holding the session, or null while it is vacant. */
    val holder: EngineId? get() = (state as? SessionState.Held)?.holder
}

/**
 * Who holds a session. A vacant session is alive, so a server move or a rejoin takes it over and nothing it owns ends,
 * but nobody holds it: its engine released it when the protagonist left, and nothing is sent there.
 */
sealed interface SessionState {
    /** [holder] holds the session; its connection began at [connected] on its own clock. */
    data class Held(
        val holder: EngineId,
        val connected: Instant,
    ) : SessionState

    data object Vacant : SessionState
}

/** What a session's lease keeps besides its holder and claim: whose session it is and since when it runs. */
internal data class SessionValue(
    val protagonist: Protagonist,
    val since: Instant,
)

/**
 * The bucket key of a session, `<principal kind>.<principal id>.<session id>`, so every session of a protagonist
 * shares the prefix [protagonistKeys] matches.
 */
internal fun sessionKey(
    protagonist: Protagonist,
    id: SessionId,
): String = "${protagonist.principal.kind}.${protagonist.principal.id}.${id.value}"

/** The key filter matching every session of [protagonist]. */
internal fun protagonistKeys(protagonist: Protagonist): String = "${protagonist.principal.kind}.${protagonist.principal.id}.*"

/**
 * Session entries as the sessions bucket stores them. A value no engine can read, damaged or cut off, is logged and
 * read as no entry, so a join writes over it and a holder listing skips it.
 */
internal object SessionLeaseCodec : LeaseCodec<SessionValue> {
    private val log: Logger = Logger.getLogger(SessionLeaseCodec::class.java.name)

    override fun encode(entry: LeaseEntry<SessionValue>): ByteArray =
        WireSessionEntry.serializer
            .toBytes(
                WireSessionEntry(
                    protagonist =
                        WireProtagonist(
                            principal =
                                WirePrincipalId(
                                    kind = entry.value.protagonist.principal.kind,
                                    id = entry.value.protagonist.principal.id,
                                ),
                        ),
                    since = entry.value.since,
                    state =
                        when (val state = entry.state) {
                            is LeaseState.Held -> {
                                WireSessionState.HeldWrapper(
                                    WireSessionHold(holder = WireEngineId(value = state.holder), connected = state.claimed),
                                )
                            }

                            LeaseState.Vacant -> {
                                WireSessionState.VACANT
                            }
                        },
                ),
            ).toByteArray()

    override fun decode(bytes: ByteArray): LeaseEntry<SessionValue>? =
        try {
            val wire = WireSessionEntry.serializer.fromBytes(bytes.toByteString())
            val state =
                when (val state = wire.state) {
                    is WireSessionState.HeldWrapper -> LeaseState.Held(state.value.holder.value, state.value.connected)
                    WireSessionState.VACANT -> LeaseState.Vacant
                    else -> return unreadable("a session state no engine knows: $state")
                }
            LeaseEntry(
                state,
                SessionValue(Protagonist(PrincipalId(wire.protagonist.principal.kind, wire.protagonist.principal.id)), wire.since),
            )
        } catch (failure: IllegalArgumentException) {
            unreadable(failure)
        } catch (failure: IOException) {
            // A cut off value ends the decoder's input early.
            unreadable(failure)
        }

    private fun unreadable(failure: Any): Nothing? {
        log.warning("Skipped a session value no engine can read: $failure")
        return null
    }
}

internal fun LeaseEntry<SessionValue>.toSessionEntry(): SessionEntry =
    SessionEntry(
        protagonist = value.protagonist,
        since = value.since,
        state =
            when (val state = state) {
                is LeaseState.Held -> SessionState.Held(EngineId(state.holder), state.claimed)
                LeaseState.Vacant -> SessionState.Vacant
            },
    )

/** The live entry of [protagonist]'s session [id] in this sessions bucket, or null when there is none or no engine can read it; a failed read throws its cause. */
suspend fun KeyValueBucket.readSessionEntry(
    protagonist: Protagonist,
    id: SessionId,
): SessionEntry? =
    when (val read = get(sessionKey(protagonist, id))) {
        is KeyValueRead.Found -> SessionLeaseCodec.decode(read.entry.value)?.toSessionEntry()
        KeyValueRead.Absent -> null
        is KeyValueRead.Failed -> throw read.cause
    }
