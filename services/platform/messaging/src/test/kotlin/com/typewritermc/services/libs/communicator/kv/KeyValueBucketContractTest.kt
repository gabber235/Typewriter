package com.typewritermc.services.libs.communicator.kv

import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.longs.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * What every key value store does, checked on the memory buckets and on a real nats-server alike, so tests on the
 * memory buckets prove what holds on the broker. A key that must still live is written with a time to live of minutes;
 * an expiry is waited for with a bound far above its time to live.
 */
val KeyValueBucketContractTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    for (start in listOf({ KeyValueStore.Memory() }, { KeyValueStore.Broker.start() })) {
        val probe = start().also { it.close() }
        testSuite(probe.name) {
            val store = testFixture { start() }
            val long = 5.minutes

            test("a bucket is missing until its owner creates it") {
                store().buckets.open("never-created") shouldBe KeyValueOpen.Missing
            }

            test("a created key reads back with the revision its write returned") {
                val bucket = store().freshBucket()

                val written = bucket.create("a.b", byteArrayOf(1, 2), long).shouldBeInstanceOf<KeyValueWrite.Written>()

                val read = bucket.get("a.b").shouldBeInstanceOf<KeyValueRead.Found>()
                read.entry.value.toList() shouldBe listOf<Byte>(1, 2)
                read.entry.revision shouldBe written.revision
            }

            test("a key that was never written reads as absent") {
                store().freshBucket().get("a.b") shouldBe KeyValueRead.Absent
            }

            test("a create over a live key conflicts and leaves it unchanged") {
                val bucket = store().freshBucket()
                bucket.create("a.b", byteArrayOf(1), long)

                bucket.create("a.b", byteArrayOf(2), long) shouldBe KeyValueWrite.Conflict

                bucket
                    .get("a.b")
                    .shouldBeInstanceOf<KeyValueRead.Found>()
                    .entry.value
                    .toList() shouldBe listOf<Byte>(1)
            }

            test("an update at the key's revision writes a later revision, and one at an older revision conflicts") {
                val bucket = store().freshBucket()
                val first = bucket.create("a.b", byteArrayOf(1), long).shouldBeInstanceOf<KeyValueWrite.Written>()

                val second = bucket.update("a.b", byteArrayOf(2), long, first.revision).shouldBeInstanceOf<KeyValueWrite.Written>()
                val stale = bucket.update("a.b", byteArrayOf(3), long, first.revision)

                second.revision shouldBeGreaterThan first.revision
                stale shouldBe KeyValueWrite.Conflict
                bucket
                    .get("a.b")
                    .shouldBeInstanceOf<KeyValueRead.Found>()
                    .entry.value
                    .toList() shouldBe listOf<Byte>(2)
            }

            test("an update of a key that was never written conflicts") {
                store().freshBucket().update("a.b", byteArrayOf(1), long, revision = 1) shouldBe KeyValueWrite.Conflict
            }

            test("a key listing names the live keys its filter matches") {
                val bucket = store().freshBucket()
                listOf("minecraft.alex.one", "minecraft.alex.two", "minecraft.sam.one", "user.alex.one").forEach {
                    bucket.create(it, byteArrayOf(1), long)
                }

                bucket
                    .keys("minecraft.alex.*")
                    .shouldBeInstanceOf<KeyValueKeys.Listed>()
                    .keys
                    .sorted() shouldContainExactly
                    listOf("minecraft.alex.one", "minecraft.alex.two")
                bucket
                    .keys("minecraft.>")
                    .shouldBeInstanceOf<KeyValueKeys.Listed>()
                    .keys
                    .sorted() shouldContainExactly
                    listOf("minecraft.alex.one", "minecraft.alex.two", "minecraft.sam.one")
            }

            test("a key expires once its time to live passed, and then a create writes it again") {
                val bucket = store().freshBucket()
                val old = bucket.create("a.b", byteArrayOf(1), 1.seconds).shouldBeInstanceOf<KeyValueWrite.Written>()

                store().outlive(1.seconds) { bucket.get("a.b") == KeyValueRead.Absent }

                bucket.keys("a.*").shouldBeInstanceOf<KeyValueKeys.Listed>().keys shouldBe emptyList()
                bucket.update("a.b", byteArrayOf(2), long, old.revision) shouldBe KeyValueWrite.Conflict
                bucket.create("a.b", byteArrayOf(3), long).shouldBeInstanceOf<KeyValueWrite.Written>()
            }

            test("an update with a shorter time to live makes the key expire sooner") {
                val bucket = store().freshBucket()
                val first = bucket.create("a.b", byteArrayOf(1), long).shouldBeInstanceOf<KeyValueWrite.Written>()

                bucket.update("a.b", byteArrayOf(1), 1.seconds, first.revision).shouldBeInstanceOf<KeyValueWrite.Written>()

                store().outlive(1.seconds) { bucket.get("a.b") == KeyValueRead.Absent }
            }
        }
    }
}
