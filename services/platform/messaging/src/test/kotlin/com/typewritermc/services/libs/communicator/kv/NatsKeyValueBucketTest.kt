package com.typewritermc.services.libs.communicator.kv

import com.typewritermc.services.libs.communicator.testing.unansweredKeyValueBucket
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlin.time.Duration.Companion.seconds

/** A broker request that natskt gives up on is a failure its caller can retry, never a cancellation of the caller. */
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
}
