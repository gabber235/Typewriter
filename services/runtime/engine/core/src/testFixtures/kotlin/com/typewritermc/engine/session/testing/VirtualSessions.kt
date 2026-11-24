package com.typewritermc.engine.session.testing

import com.typewritermc.engine.session.SessionEntry
import com.typewritermc.engine.session.SessionKeeper
import com.typewritermc.engine.session.SessionLeaseCodec
import com.typewritermc.engine.session.SessionValue
import com.typewritermc.engine.session.sessionKey
import com.typewritermc.engine.session.toSessionEntry
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.kv.LeaseEntry
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.testing.ScriptedBuckets
import com.typewritermc.services.libs.communicator.testing.VirtualKeyValue
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import java.time.Instant
import java.util.UUID

/**
 * Engines of one Realm keeping sessions in a sessions bucket in memory, all on the virtual time of [scope]: each engine
 * reaches the bucket through its own [ScriptedBuckets], and [keyValue] moves time for all of them. Timings are
 * [SessionHarness.SHORT]: refresh every 300 ms, live 2 s, a grace of 1 s.
 */
class VirtualSessions(
    private val scope: TestScope,
    val timings: LeaseTimings = SessionHarness.SHORT,
) {
    val keyValue = VirtualKeyValue(scope)

    /** A Minecraft player, a protagonist whose session id is its UUID. */
    fun player(): Pair<Protagonist, SessionId> {
        val uuid = UUID.randomUUID().toString()
        return Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid)) to SessionId(uuid)
    }

    /** Creates the Realm's sessions bucket, as the Realm does when it starts. */
    suspend fun createBucket() = keyValue.createBucket(BUCKET)

    /** Starts engine [id] of the Realm with its own way to the bucket. */
    fun engine(id: String): VirtualEngine {
        val buckets = ScriptedBuckets(keyValue.store)
        val keeper = SessionKeeper(EngineId(id), MutableStateFlow(buckets), BUCKET, timings, scope.backgroundScope, keyValue.clock())
        return VirtualEngine(EngineId(id), keeper, buckets)
    }

    /** The live entry of [protagonist]'s session [id], or null when there is none or no engine can read it. */
    suspend fun entry(
        protagonist: Protagonist,
        id: SessionId,
    ): SessionEntry? = keyValue.read(sessionKey(protagonist, id), BUCKET)?.let(SessionLeaseCodec::decode)?.toSessionEntry()

    /** Writes an empty value no engine can read under [protagonist]'s session [id], as a damaged write would. */
    suspend fun unreadable(
        protagonist: Protagonist,
        id: SessionId,
    ) = keyValue.write(sessionKey(protagonist, id), ByteArray(0), timings.ttl, BUCKET)

    /** Writes the first half of a real session entry under [protagonist]'s session [id], as a cut off write would. */
    suspend fun truncated(
        protagonist: Protagonist,
        id: SessionId,
    ) {
        val whole = SessionLeaseCodec.encode(LeaseEntry("engine-gone", Instant.EPOCH, SessionValue(protagonist, Instant.EPOCH)))
        keyValue.write(sessionKey(protagonist, id), whole.copyOf(whole.size / 2), timings.ttl, BUCKET)
    }

    companion object {
        /** The Realm's sessions bucket in memory. */
        const val BUCKET: String = "sessions"
    }
}

/** One engine of [VirtualSessions]; [buckets] is its way to the sessions bucket. */
class VirtualEngine(
    val id: EngineId,
    val keeper: SessionKeeper,
    val buckets: ScriptedBuckets,
)
