package com.typewritermc.services.libs.communicator.testing

import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.arbitrary.bind
import io.kotest.property.arbitrary.choice
import io.kotest.property.arbitrary.enum
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import java.time.Instant
import kotlin.time.Duration.Companion.milliseconds

/**
 * A generated run of three holders on one key: claims, releases and crashes, each request of every holder held until
 * a step delivers it, lost its answer or failed it, and time passing in between. Holders are numbered 0 to 2.
 */
class LeaseSchedule(
    val steps: List<LeaseStep>,
) {
    override fun toString(): String = steps.joinToString(", ")

    companion object {
        /** Schedules of up to 40 steps. */
        val arb: Arb<LeaseSchedule> =
            Arb
                .list(
                    Arb.choice(
                        Arb.int(0..2).map { LeaseStep.Claim(it) },
                        Arb.int(0..2).map { LeaseStep.Release(it) },
                        Arb.int(0..2).map { LeaseStep.Crash(it) },
                        Arb.bind(Arb.int(0..20), Arb.enum<Delivery>()) { index, how -> LeaseStep.Deliver(index, how) },
                        Arb.bind(Arb.int(0..20), Arb.enum<Delivery>()) { index, how -> LeaseStep.Deliver(index, how) },
                        Arb.int(1..700).map { LeaseStep.Wait(it) },
                    ),
                    1..40,
                ).map(::LeaseSchedule)
    }
}

/** One step of a [LeaseSchedule]. */
sealed interface LeaseStep {
    data class Claim(
        val holder: Int,
    ) : LeaseStep

    data class Release(
        val holder: Int,
    ) : LeaseStep

    /** The holder stops for good, as a crashed engine does. */
    data class Crash(
        val holder: Int,
    ) : LeaseStep

    /** Resolves the held request at [index] (wrapped around) among every holder's held requests. */
    data class Deliver(
        val index: Int,
        val how: Delivery,
    ) : LeaseStep

    data class Wait(
        val millis: Int,
    ) : LeaseStep
}

/** What happens to a delivered request. */
enum class Delivery { LAND, LAND_AND_FAIL, FAIL }

/** Plays [schedule] on a fresh key with fresh holders, then lets every held request land and the holders settle. */
suspend fun VirtualLeases.play(schedule: LeaseSchedule): PlayedSchedule {
    keyValue.createBucket()
    val key = "played.${keyValue.clock().instant().toEpochMilli()}.${System.identityHashCode(schedule)}"
    val holders = List(3) { holder("engine-$it") }
    holders.forEach { it.buckets.holdEvery = true }
    val claims = mutableListOf<PlayedClaim>()
    val last = arrayOfNulls<LeaseStep>(3)
    for (step in schedule.steps) {
        when (step) {
            is LeaseStep.Claim -> {
                if (last[step.holder] !is LeaseStep.Crash) {
                    claims += PlayedClaim(holders[step.holder].id, keyValue.clock().instant())
                    holders[step.holder].claim(key)
                    last[step.holder] = step
                }
            }

            is LeaseStep.Release -> {
                if (last[step.holder] !is LeaseStep.Crash) {
                    holders[step.holder].release(key)
                    last[step.holder] = step
                }
            }

            is LeaseStep.Crash -> {
                holders[step.holder].crash()
                last[step.holder] = step
            }

            is LeaseStep.Deliver -> {
                val pending = holders.flatMap { it.buckets.pending }
                if (pending.isNotEmpty()) {
                    val request = pending[step.index % pending.size]
                    when (step.how) {
                        Delivery.LAND -> request.land()
                        Delivery.LAND_AND_FAIL -> request.landAndFail()
                        Delivery.FAIL -> request.fail()
                    }
                }
            }

            is LeaseStep.Wait -> {
                keyValue.advance(step.millis.milliseconds)
            }
        }
        keyValue.settle()
    }
    holders.forEach { it.buckets.holdEvery = false }
    while (true) {
        val pending = holders.flatMap { it.buckets.pending }
        if (pending.isEmpty()) break
        pending.forEach { it.land() }
        keyValue.settle()
    }
    keyValue.advance(timings.refresh * 2 + timings.retry * 2)
    val standing =
        holders.indices
            .filter { last[it] is LeaseStep.Claim }
            .map { holders[it].id }
            .toSet()
    return PlayedSchedule(this, key, holders, claims, standing)
}

/** One claim a schedule made: its holder and the instant on that holder's clock. */
class PlayedClaim(
    val holder: String,
    val claimed: Instant,
)

/** A schedule played to its end, with every request landed and the holders settled. */
class PlayedSchedule internal constructor(
    private val leases: VirtualLeases,
    private val key: String,
    private val holders: List<LeaseHolder>,
    private val claims: List<PlayedClaim>,
    private val standing: Set<String>,
) {
    /**
     * The guarantees every schedule keeps: the newest claim ever made holds the key, past its time to live, whenever its
     * holder still stands by it; and with no claim standing the key ends within the time to live and the vacancy. Every
     * holder stops afterwards.
     */
    suspend fun shouldEndWithNewestClaimHolding() {
        try {
            val newest = claims.maxWithOrNull(compareBy<PlayedClaim>({ it.claimed }, { it.holder }))
            if (newest != null && newest.holder in standing) {
                leases.keyValue.advance(leases.timings.ttl * 2)
                leases.entry(key).shouldNotBeNull().holder shouldBe newest.holder
            }
            if (standing.isEmpty()) {
                leases.keyValue.advance(leases.timings.ttl + leases.timings.vacancy)
                leases.entry(key).shouldBeNull()
            }
        } finally {
            holders.forEach { it.crash() }
        }
    }
}
