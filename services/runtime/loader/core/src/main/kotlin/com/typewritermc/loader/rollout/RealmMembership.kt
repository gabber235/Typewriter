package com.typewritermc.loader.rollout

import skirout.service.v1.rollout.RealmHostPresence
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Who belongs to the Realm right now: the hosts its rollout converges. A host that is not listed has left, crashed or
 * been silent for longer than its lease allows; nothing waits for it, and it is converged again once it is listed.
 */
fun interface RealmMembership {
    suspend fun members(): List<RealmHostPresence>
}

/** One presence probe: the hosts that answered it. A host missing from one probe may only have answered late. */
fun interface PresenceProbe {
    suspend fun answering(): List<RealmHostPresence>
}

/**
 * Membership read from repeated presence probes with lease semantics, the rule leased presence rows give as well:
 * every answer renews a host's lease, and a host stays a member, with the presence it last answered with, until it has
 * been silent for longer than [grace].
 *
 * The default grace of ten seconds covers one probe missed during the slowest regular pass (the probe, a status
 * request that waits its full five seconds and the one second pause, about six and a half seconds), so one late answer
 * never drops a host, while a host that is really gone stops counting within a third of the healthy window.
 *
 * Reads come from one rollout loop at a time.
 */
class ProbedRealmMembership(
    private val probe: PresenceProbe,
    private val grace: Duration = DEFAULT_GRACE,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) : RealmMembership {
    private val leases = mutableMapOf<String, Lease>()

    override suspend fun members(): List<RealmHostPresence> {
        val answers = probe.answering()
        val renewed = timeSource.markNow()
        answers.forEach { leases[it.serviceId] = Lease(it, renewed) }
        leases.values.removeAll { it.renewed.elapsedNow() > grace }
        return leases.values.map(Lease::presence)
    }

    private class Lease(
        val presence: RealmHostPresence,
        val renewed: TimeMark,
    )

    companion object {
        val DEFAULT_GRACE: Duration = 10.seconds
    }
}
