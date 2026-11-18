package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.io.PipedInputStream
import java.io.PipedOutputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

val EndOfInputTest by testSuite {
    test("the pool stops once the build closes its input, and not while the input stays open") {
        val build = PipedOutputStream()
        val input = PipedInputStream(build)
        val stopped = CountDownLatch(1)

        onEndOf(input) { stopped.countDown() }
        build.write("still building\n".toByteArray())
        build.flush()

        stopped.await(300, TimeUnit.MILLISECONDS) shouldBe false
        build.close()
        stopped.await(5, TimeUnit.SECONDS) shouldBe true
    }
}
