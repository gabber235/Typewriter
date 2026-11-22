package com.typewritermc.services.libs.communicator.kv

import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.onBroker
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * A watch on a real nats-server with JetStream: the broker alone decides when a key expires and leaves its marker.
 * Each test runs on real time, since the broker answers on its own threads.
 */
val KeyValueWatchTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val server = testFixture { NatsTestServer.startWithJetStream() }

    test("WATCH-1 a watch sees each write of a key as a put, in the order written") {
        onBroker(server().url) {
            val bucket = (buckets().ensure(KeyValueBucketDeclaration("writes", markerTtl = 5.seconds)) as KeyValueOpen.Opened).bucket
            val changes = Channel<KeyValueChange>(Channel.UNLIMITED)
            val watching = bucket.watch(">").shouldBeInstanceOf<KeyValueWatch.Watching>()
            val watcher = launch { watching.changes.collect(changes::send) }
            withTimeout(5.seconds) { changes.receive() } shouldBe KeyValueChange.CaughtUp

            val first = (bucket.create("a.b", byteArrayOf(1), 10.seconds) as KeyValueWrite.Written).revision
            bucket.update("a.b", byteArrayOf(2), 10.seconds, first)

            withTimeout(5.seconds) {
                changes
                    .receive()
                    .shouldBeInstanceOf<KeyValueChange.Put>()
                    .entry.value
                    .toList() shouldBe listOf<Byte>(1)
                changes
                    .receive()
                    .shouldBeInstanceOf<KeyValueChange.Put>()
                    .entry.value
                    .toList() shouldBe listOf<Byte>(2)
            }
            watcher.cancel()
        }
    }

    test("WATCH-2 a key whose time to live ran out reaches the watch as an expiry, and a rewritten one does not") {
        onBroker(server().url) {
            val bucket = (buckets().ensure(KeyValueBucketDeclaration("expiry", markerTtl = 5.seconds)) as KeyValueOpen.Opened).bucket
            val changes = Channel<KeyValueChange>(Channel.UNLIMITED)
            val watching = bucket.watch(">").shouldBeInstanceOf<KeyValueWatch.Watching>()
            val watcher = launch { watching.changes.collect(changes::send) }
            withTimeout(5.seconds) { changes.receive() } shouldBe KeyValueChange.CaughtUp

            val revision = (bucket.create("short", byteArrayOf(1), 1.seconds) as KeyValueWrite.Written).revision
            bucket.update("short", byteArrayOf(2), 1.seconds, revision)

            withTimeout(5.seconds) {
                changes
                    .receive()
                    .shouldBeInstanceOf<KeyValueChange.Put>()
                    .entry.key shouldBe "short"
                changes
                    .receive()
                    .shouldBeInstanceOf<KeyValueChange.Put>()
                    .entry.key shouldBe "short"
                changes.receive() shouldBe KeyValueChange.Expired("short")
            }
            withTimeoutOrNull(2.seconds) { changes.receive() } shouldBe null
            watcher.cancel()
        }
    }

    test("WATCH-3 a watch started later first sees each key's latest state, a kept expiry marker included") {
        onBroker(server().url) {
            val bucket = (buckets().ensure(KeyValueBucketDeclaration("late", markerTtl = 30.seconds)) as KeyValueOpen.Opened).bucket
            bucket.create("live", byteArrayOf(7), 30.seconds)
            bucket.create("gone", byteArrayOf(8), 1.seconds)
            withTimeout(5.seconds) { while (bucket.get("gone") != KeyValueRead.Absent) delay(100.milliseconds) }

            val changes = Channel<KeyValueChange>(Channel.UNLIMITED)
            val watching = bucket.watch(">").shouldBeInstanceOf<KeyValueWatch.Watching>()
            val watcher = launch { watching.changes.collect(changes::send) }

            val seen = withTimeout(5.seconds) { listOf(changes.receive(), changes.receive()) }
            seen.filterIsInstance<KeyValueChange.Put>().map { it.entry.key to it.entry.value.toList() } shouldBe
                listOf("live" to listOf<Byte>(7))
            seen.filterIsInstance<KeyValueChange.Expired>() shouldBe listOf(KeyValueChange.Expired("gone"))
            watcher.cancel()
        }
    }

    test("WATCH-5 a watch of an empty bucket says at once that it caught up, then reports the first write") {
        onBroker(server().url) {
            val bucket = (buckets().ensure(KeyValueBucketDeclaration("empty", markerTtl = 5.seconds)) as KeyValueOpen.Opened).bucket
            val changes = Channel<KeyValueChange>(Channel.UNLIMITED)
            val watching = bucket.watch(">").shouldBeInstanceOf<KeyValueWatch.Watching>()
            val watcher = launch { watching.changes.collect(changes::send) }
            withTimeout(5.seconds) { changes.receive() } shouldBe KeyValueChange.CaughtUp

            bucket.create("first", byteArrayOf(1), 30.seconds)

            withTimeout(5.seconds) {
                changes
                    .receive()
                    .shouldBeInstanceOf<KeyValueChange.Put>()
                    .entry.key shouldBe "first"
            }
            watcher.cancel()
        }
    }

    test("WATCH-6 a watch says it caught up once, right after the latest state of every key, before any later write") {
        onBroker(server().url) {
            val bucket = (buckets().ensure(KeyValueBucketDeclaration("replay", markerTtl = 5.seconds)) as KeyValueOpen.Opened).bucket
            listOf("a", "b", "c").forEach { bucket.create(it, byteArrayOf(1), 30.seconds) }

            val changes = Channel<KeyValueChange>(Channel.UNLIMITED)
            val watching = bucket.watch(">").shouldBeInstanceOf<KeyValueWatch.Watching>()
            val watcher = launch { watching.changes.collect(changes::send) }
            val replayed = withTimeout(5.seconds) { List(4) { changes.receive() } }
            bucket.create("d", byteArrayOf(1), 30.seconds)
            val later = withTimeout(5.seconds) { changes.receive() }

            replayed.dropLast(1).map { (it as KeyValueChange.Put).entry.key } shouldBe listOf("a", "b", "c")
            replayed.last() shouldBe KeyValueChange.CaughtUp
            (later as KeyValueChange.Put).entry.key shouldBe "d"
            withTimeoutOrNull(1.seconds) { changes.receive() } shouldBe null
            watcher.cancel()
        }
    }
}
