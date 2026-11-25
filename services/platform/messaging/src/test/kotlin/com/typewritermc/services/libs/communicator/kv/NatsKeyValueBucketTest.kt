package com.typewritermc.services.libs.communicator.kv

import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import com.typewritermc.services.libs.communicator.testing.unansweredKeyValueBucket
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * A broker request that natskt gives up on is a failure its caller can retry, never a cancellation of the caller; a
 * write the broker refused is never sent again, since it can only be refused again.
 */
val NatsKeyValueBucketTest by testSuite {
    test("a read whose broker reply never came fails") {
        unansweredKeyValueBucket().get("key").shouldBeInstanceOf<KeyValueRead.Failed>()
    }

    test("a write whose broker reply never came fails") {
        unansweredKeyValueBucket().create("key", byteArrayOf(1), 1.seconds).shouldBeInstanceOf<KeyValueWrite.Failed>()
        unansweredKeyValueBucket().update("key", byteArrayOf(1), 1.seconds, revision = 1).shouldBeInstanceOf<KeyValueWrite.Failed>()
    }

    test("a key listing whose broker reply never came fails") {
        unansweredKeyValueBucket().keys("*").shouldBeInstanceOf<KeyValueKeys.Failed>()
    }

    testSuite("on a broker", testConfig = TestConfig.testScope(isEnabled = false)) {
        val store = testFixture { KeyValueStore.Broker.start() }

        test("a write at a stale revision conflicts after sending it once") {
            val opened = store().buckets.ensure(KeyValueBucketDeclaration("conflicts", markerTtl = 1.seconds))
            val bucket = opened.shouldBeInstanceOf<KeyValueOpen.Opened>().bucket
            val first = bucket.create("a.b", byteArrayOf(1), 5.minutes).shouldBeInstanceOf<KeyValueWrite.Written>()
            bucket.update("a.b", byteArrayOf(2), 5.minutes, first.revision).shouldBeInstanceOf<KeyValueWrite.Written>()
            lateinit var stale: KeyValueWrite

            val sent = store().publishesTo("conflicts", "a.b") { stale = bucket.update("a.b", byteArrayOf(3), 5.minutes, first.revision) }

            stale shouldBe KeyValueWrite.Conflict
            sent shouldBe 1
        }
    }
}
