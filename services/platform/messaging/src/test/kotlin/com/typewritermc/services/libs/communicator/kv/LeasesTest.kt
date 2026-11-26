package com.typewritermc.services.libs.communicator.kv

import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import com.typewritermc.services.libs.communicator.testing.LeaseSchedule
import com.typewritermc.services.libs.communicator.testing.RequestKind
import com.typewritermc.services.libs.communicator.testing.SentRequest
import com.typewritermc.services.libs.communicator.testing.VirtualLeases
import com.typewritermc.services.libs.communicator.testing.play
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.property.PropTestConfig
import io.kotest.property.checkAll
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Leases on virtual time over memory buckets the bucket contract keeps honest: every interleaving of claims, releases,
 * lost answers and outages is set up exactly, and every expiry is checked at the instant it is due. Timings are
 * [VirtualLeases.SHORT]: refresh 300 ms, live 2 s, a vacancy of 1 s, a retry after 100 ms.
 */
val LeasesTest by testSuite {
    val ttl = VirtualLeases.SHORT.ttl
    val vacancy = VirtualLeases.SHORT.vacancy
    val refresh = VirtualLeases.SHORT.refresh
    val retry = VirtualLeases.SHORT.retry

    test("LEASE-1 a claim writes the key naming its holder and the instant it was claimed") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")

        a.claim("k")
        leases.store.settle()

        leases.entry("k") shouldBe LeaseEntry(LeaseState.Held("engine-a", KeyValueStore.Memory.START), "first")
    }

    test("LEASE-2 a held key outlives its time to live") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")

        leases.store.advance(ttl * 10)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
    }

    test("LEASE-3 a released key stays alive held by nobody, and ends once the vacancy passed") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.store.advance(ttl)

        a.release("k")
        leases.store.advance(vacancy - 1.milliseconds)
        leases.entry("k") shouldBe LeaseEntry(LeaseState.Vacant, "first")
        leases.store.advance(1.milliseconds)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-4 a crashed holder's key ends within the time to live") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.store.settle()

        a.crash()
        leases.store.advance(ttl)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-5 a newer claim takes a held key over, and the old holder stops holding it and never writes it again") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        val b = leases.holder("engine-b")
        a.claim("k")
        leases.store.advance(1.milliseconds)

        b.claim("k")
        leases.store.advance(refresh)
        val writesBefore = a.buckets.sent.count { it == SentRequest(RequestKind.WRITE, "k") }
        leases.store.advance(ttl * 3)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-b"
        a.buckets.sent.count { it == SentRequest(RequestKind.WRITE, "k") } shouldBe writesBefore
    }

    test("LEASE-6 a claim older than the key's claim never writes over it, however late it reads the key") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        val b = leases.holder("engine-b")
        val read = a.buckets.holdNext(RequestKind.READ)
        a.claim("k")
        leases.store.advance(1.milliseconds)
        b.claim("k")
        leases.store.settle()
        val taken = leases.entry("k").shouldNotBeNull()

        read.land()
        leases.store.advance(ttl * 3)

        leases.entry("k") shouldBe taken
    }

    test("LEASE-7 two claims that read the same revision end with the newer one holding, whichever write lands first") {
        for (newerFirst in listOf(true, false)) {
            val leases = VirtualLeases(testScope).apply { createBucket() }
            val (older, newer) = leases.holder("engine-b") to leases.holder("engine-a")
            leases.holder("engine-c").claim("k")
            leases.store.advance(1.milliseconds)
            val olderWrite = older.buckets.holdNext(RequestKind.WRITE)
            val newerWrite = newer.buckets.holdNext(RequestKind.WRITE)
            older.claim("k")
            leases.store.advance(1.milliseconds)
            newer.claim("k")
            leases.store.settle()

            val (first, second) = if (newerFirst) newerWrite to olderWrite else olderWrite to newerWrite
            first.land()
            leases.store.settle()
            second.land()
            leases.store.advance(ttl * 3)

            leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
        }
    }

    test("LEASE-8 claims at the same instant end with the greater holder id holding, whichever writes first") {
        for (firstToLand in listOf("engine-a", "engine-b")) {
            val leases = VirtualLeases(testScope).apply { createBucket() }
            val holders = listOf(leases.holder("engine-a"), leases.holder("engine-b"))
            val writes = holders.associate { it.id to it.buckets.holdNext(RequestKind.WRITE) }
            holders.forEach { it.claim("k") }
            leases.store.settle()

            writes.getValue(firstToLand).land()
            leases.store.settle()
            writes
                .filterKeys { it != firstToLand }
                .values
                .single()
                .land()
            leases.store.advance(ttl * 3)

            leases.entry("k").shouldNotBeNull().holder shouldBe "engine-b"
        }
    }

    test("LEASE-9 a claim released before it wrote anything writes nothing") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        val read = a.buckets.holdNext(RequestKind.READ)
        a.claim("k")

        a.release("k")
        read.land()
        leases.store.settle()

        leases.entry("k").shouldBeNull()
        leases.store.advance(ttl * 3)
        leases.entry("k").shouldBeNull()
    }

    test("LEASE-10 a claim whose write reached the store after its release still ends once the vacancy passed") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        val write = a.buckets.holdNext(RequestKind.WRITE)
        a.claim("k")
        leases.store.settle()

        a.release("k")
        write.land()
        leases.store.settle()
        leases.entry("k").shouldNotBeNull()
        leases.store.advance(vacancy)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-11 a release that cuts off a refresh whose write landed still ends the key once the vacancy passed") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.store.settle()
        val refreshed = a.buckets.holdNext(RequestKind.WRITE)
        leases.store.advance(refresh)
        refreshed.landAndHang()
        leases.store.settle()

        a.release("k")
        leases.store.settle()
        leases.store.advance(vacancy)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-12 a claim whose write landed but whose answer was lost holds the key") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        val write = a.buckets.holdNext(RequestKind.WRITE)
        a.claim("k")
        leases.store.settle()

        write.landAndFail()
        leases.store.advance(ttl * 3)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
    }

    test("LEASE-13 an outage shorter than the time to live ends nothing") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.store.settle()

        a.buckets.unreachable = true
        leases.store.advance(ttl - refresh)
        a.buckets.unreachable = false
        leases.store.advance(ttl * 3)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
    }

    test("LEASE-14 a key that expired during a longer outage is written again once the store is back") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.store.settle()

        a.buckets.unreachable = true
        leases.store.advance(ttl * 2)
        leases.entry("k").shouldBeNull()
        a.buckets.unreachable = false
        leases.store.advance(refresh)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
    }

    test("LEASE-15 a release during an outage ends the key once the store is back and the vacancy passed") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.store.settle()

        a.buckets.unreachable = true
        a.release("k")
        leases.store.advance(refresh)
        a.buckets.unreachable = false
        leases.store.advance(retry + vacancy)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-16 a claim made before the bucket exists is written once it does") {
        val leases = VirtualLeases(testScope)
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.store.advance(ttl)

        leases.createBucket()
        leases.store.advance(retry)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
    }

    test("LEASE-17 a value no holder can read is claimed over, and listing entries skips it") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        leases.write("x.1", "unreadable".encodeToByteArray(), ttl)
        leases.write("x.2", "unreadable".encodeToByteArray(), ttl)

        a.claim("x.1")
        leases.store.settle()

        leases.entry("x.1").shouldNotBeNull().holder shouldBe "engine-a"
        a.leases.entries("x.*").map { it.holder } shouldContainExactly listOf("engine-a")
    }

    test("LEASE-18 a claim stamped further ahead than the skew bound is counted, and wins as the newer claim") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val ahead = leases.holder("engine-b", ahead = 5.seconds)
        val a = leases.holder("engine-a")
        ahead.claim("k")
        leases.store.settle()

        a.claim("k")
        leases.store.advance(ttl)

        leases.telemetry.counted("typewriter.lease.claim.ahead") shouldBe 1
        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-b"
    }

    test(
        "LEASE-19 after any schedule of claims, releases, crashes and broker faults, the newest claim holds the key while its holder stands by it, and the key ends once no claim stands",
    ) {
        checkAll(PropTestConfig(seed = 4242, iterations = 400), LeaseSchedule.arb) { schedule ->
            VirtualLeases(testScope).play(schedule).shouldEndWithNewestClaimHolding()
        }
    }

    test("LEASE-20 any claim takes a vacant key over, also one older than the claim that was released") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val released = leases.holder("engine-b", ahead = 500.milliseconds)
        val a = leases.holder("engine-a")
        released.claim("k")
        leases.store.settle()
        released.release("k")
        leases.store.settle()

        a.claim("k")
        leases.store.advance(ttl * 3)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
    }

    test("LEASE-21 a release after a newer claim took the key over leaves the key to the newer claim") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val a = leases.holder("engine-a")
        val b = leases.holder("engine-b")
        a.claim("k")
        leases.store.advance(1.milliseconds)
        b.claim("k")
        leases.store.settle()

        a.release("k")
        leases.store.advance(ttl * 3)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-b"
    }

    test("LEASE-22 a holder whose key a newer claim took has lost it for good, also once the newer holder released it") {
        val leases = VirtualLeases(testScope).apply { createBucket() }
        val b = leases.holder("engine-b")
        val a = leases.holder("engine-a")
        b.claim("k")
        leases.store.advance(1.milliseconds)
        a.claim("k")
        leases.store.settle()

        a.release("k")
        leases.store.advance(refresh)
        leases.entry("k") shouldBe LeaseEntry(LeaseState.Vacant, "first")
        leases.store.advance(vacancy)

        leases.entry("k").shouldBeNull()
    }
}
