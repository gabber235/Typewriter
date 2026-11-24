package com.typewritermc.services.libs.communicator.kv

import com.typewritermc.services.libs.communicator.testing.LeaseSchedule
import com.typewritermc.services.libs.communicator.testing.RequestKind
import com.typewritermc.services.libs.communicator.testing.VirtualKeyValue
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
 * [VirtualLeases.SHORT]: refresh 300 ms, live 2 s, a grace of 1 s, a retry after 100 ms.
 */
val LeasesTest by testSuite {
    val ttl = VirtualLeases.SHORT.ttl
    val grace = VirtualLeases.SHORT.grace
    val refresh = VirtualLeases.SHORT.refresh
    val retry = VirtualLeases.SHORT.retry

    test("LEASE-1 a claim counts as held at once and writes the key naming its holder and the instant it was claimed") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")

        a.claim("k")
        a.leases.holds("k") shouldBe true
        leases.keyValue.settle()

        leases.entry("k") shouldBe LeaseEntry("engine-a", VirtualKeyValue.START, "first")
    }

    test("LEASE-2 a held key outlives its time to live") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")

        leases.keyValue.advance(ttl * 10)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
        a.leases.holds("k") shouldBe true
    }

    test("LEASE-3 a released key ends once the grace passed") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.keyValue.advance(ttl)

        a.release("k")
        a.leases.holds("k") shouldBe false
        leases.keyValue.advance(grace - 1.milliseconds)
        leases.entry("k").shouldNotBeNull()
        leases.keyValue.advance(1.milliseconds)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-4 a crashed holder's key ends within the time to live") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.keyValue.settle()

        a.crash()
        leases.keyValue.advance(ttl)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-5 a newer claim takes a held key over, and the old holder stops holding it and never writes it again") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        val b = leases.holder("engine-b")
        a.claim("k")
        leases.keyValue.advance(1.milliseconds)

        b.claim("k")
        leases.keyValue.advance(refresh)

        a.leases.holds("k") shouldBe false
        leases.keyValue.advance(ttl * 3)
        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-b"
        b.leases.holds("k") shouldBe true
    }

    test("LEASE-6 a claim older than the key's claim never writes over it, however late it reads the key") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        val b = leases.holder("engine-b")
        val read = a.buckets.holdNext(RequestKind.READ)
        a.claim("k")
        leases.keyValue.advance(1.milliseconds)
        b.claim("k")
        leases.keyValue.settle()
        val taken = leases.entry("k").shouldNotBeNull()

        read.land()
        leases.keyValue.advance(ttl * 3)

        leases.entry("k") shouldBe taken
        a.leases.holds("k") shouldBe false
        b.leases.holds("k") shouldBe true
    }

    test("LEASE-7 two claims that read the same revision end with the newer one holding, whichever write lands first") {
        for (newerFirst in listOf(true, false)) {
            val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
            val (older, newer) = leases.holder("engine-b") to leases.holder("engine-a")
            leases.holder("engine-c").claim("k")
            leases.keyValue.advance(1.milliseconds)
            val olderWrite = older.buckets.holdNext(RequestKind.WRITE)
            val newerWrite = newer.buckets.holdNext(RequestKind.WRITE)
            older.claim("k")
            leases.keyValue.advance(1.milliseconds)
            newer.claim("k")
            leases.keyValue.settle()

            val (first, second) = if (newerFirst) newerWrite to olderWrite else olderWrite to newerWrite
            first.land()
            leases.keyValue.settle()
            second.land()
            leases.keyValue.advance(ttl * 3)

            leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
            newer.leases.holds("k") shouldBe true
            older.leases.holds("k") shouldBe false
        }
    }

    test("LEASE-8 claims at the same instant end with the greater holder id holding, whichever writes first") {
        for (firstToLand in listOf("engine-a", "engine-b")) {
            val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
            val holders = listOf(leases.holder("engine-a"), leases.holder("engine-b"))
            val writes = holders.associate { it.id to it.buckets.holdNext(RequestKind.WRITE) }
            holders.forEach { it.claim("k") }
            leases.keyValue.settle()

            writes.getValue(firstToLand).land()
            leases.keyValue.settle()
            writes.filterKeys { it != firstToLand }.values.single().land()
            leases.keyValue.advance(ttl * 3)

            leases.entry("k").shouldNotBeNull().holder shouldBe "engine-b"
            holders.map { it.leases.holds("k") } shouldContainExactly listOf(false, true)
        }
    }

    test("LEASE-9 a claim released before it wrote anything writes nothing") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        val read = a.buckets.holdNext(RequestKind.READ)
        a.claim("k")

        a.release("k")
        read.land()
        leases.keyValue.settle()

        leases.entry("k").shouldBeNull()
        leases.keyValue.advance(ttl * 3)
        leases.entry("k").shouldBeNull()
        a.leases.holds("k") shouldBe false
    }

    test("LEASE-10 a claim whose write reached the store after its release still ends once the grace passed") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        val write = a.buckets.holdNext(RequestKind.WRITE)
        a.claim("k")
        leases.keyValue.settle()

        a.release("k")
        write.land()
        leases.keyValue.settle()
        leases.entry("k").shouldNotBeNull()
        leases.keyValue.advance(grace)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-11 a release that cuts off a refresh whose write landed still ends the key once the grace passed") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.keyValue.settle()
        val refreshed = a.buckets.holdNext(RequestKind.WRITE)
        leases.keyValue.advance(refresh)
        refreshed.landAndHang()
        leases.keyValue.settle()

        a.release("k")
        leases.keyValue.settle()
        leases.keyValue.advance(grace)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-12 a claim whose write landed but whose answer was lost holds the key") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        val write = a.buckets.holdNext(RequestKind.WRITE)
        a.claim("k")
        leases.keyValue.settle()

        write.landAndFail()
        leases.keyValue.advance(ttl * 3)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
        a.leases.holds("k") shouldBe true
    }

    test("LEASE-13 an outage shorter than the time to live ends nothing") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.keyValue.settle()

        a.buckets.unreachable = true
        leases.keyValue.advance(ttl - refresh)
        a.buckets.unreachable = false
        leases.keyValue.advance(ttl * 3)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
        a.leases.holds("k") shouldBe true
    }

    test("LEASE-14 a key that expired during a longer outage is written again once the store is back") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.keyValue.settle()

        a.buckets.unreachable = true
        leases.keyValue.advance(ttl * 2)
        leases.entry("k").shouldBeNull()
        a.buckets.unreachable = false
        leases.keyValue.advance(refresh)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
        a.leases.holds("k") shouldBe true
    }

    test("LEASE-15 a release during an outage ends the key once the store is back and the grace passed") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.keyValue.settle()

        a.buckets.unreachable = true
        a.release("k")
        leases.keyValue.advance(refresh)
        a.buckets.unreachable = false
        leases.keyValue.advance(retry + grace)

        leases.entry("k").shouldBeNull()
    }

    test("LEASE-16 a claim made before the bucket exists is written once it does") {
        val leases = VirtualLeases(testScope)
        val a = leases.holder("engine-a")
        a.claim("k")
        leases.keyValue.advance(ttl)

        leases.keyValue.createBucket()
        leases.keyValue.advance(retry)

        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-a"
    }

    test("LEASE-17 a value no holder can read is claimed over, and listing entries skips it") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val a = leases.holder("engine-a")
        leases.keyValue.write("x.1", "unreadable".encodeToByteArray(), ttl)
        leases.keyValue.write("x.2", "unreadable".encodeToByteArray(), ttl)

        a.claim("x.1")
        leases.keyValue.settle()

        leases.entry("x.1").shouldNotBeNull().holder shouldBe "engine-a"
        a.leases.entries("x.*").map { it.holder } shouldContainExactly listOf("engine-a")
    }

    test("LEASE-18 a claim stamped further ahead than the skew bound is counted, and wins as the newer claim") {
        val leases = VirtualLeases(testScope).apply { keyValue.createBucket() }
        val ahead = leases.holder("engine-b", ahead = 5.seconds)
        val a = leases.holder("engine-a")
        ahead.claim("k")
        leases.keyValue.settle()

        a.claim("k")
        leases.keyValue.advance(ttl)

        leases.keyValue.telemetry.counted("typewriter.lease.claim.ahead") shouldBe 1
        leases.entry("k").shouldNotBeNull().holder shouldBe "engine-b"
        a.leases.holds("k") shouldBe false
    }

    test("LEASE-19 after any schedule of claims, releases, crashes and broker faults, the newest claim still standing holds the key") {
        checkAll(PropTestConfig(seed = 4242, iterations = 400), LeaseSchedule.arb) { schedule ->
            VirtualLeases(testScope).play(schedule).shouldEndWithNewestClaimHolding()
        }
    }
}
