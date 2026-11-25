package com.typewritermc.loader.work

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkItem
import com.typewritermc.loader.api.work.WorkObserver
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

/** A count of zero tells whoever drains the host's work that every item ended and every observer heard it. */
val InFlightWorkTest by testSuite {
    test("an observer hears an item's end while the item still counts") {
        val work = InFlightWork()
        var countAtEnd = -1
        work.observe(
            object : WorkObserver {
                override fun began(item: WorkItem) = Unit

                override fun ended(
                    item: WorkItem,
                    failure: Throwable?,
                ) {
                    countAtEnd = work.count
                }
            },
        )

        work.begin("engine task join", null).end()

        countAtEnd shouldBe 1
        work.count shouldBe 0
    }

    test("an observer that throws on an end still lets the item stop counting") {
        val work = InFlightWork()
        work.observe(
            object : WorkObserver {
                override fun began(item: WorkItem) = Unit

                override fun ended(
                    item: WorkItem,
                    failure: Throwable?,
                ): Unit = throw IllegalStateException("observer broke")
            },
        )
        val item = work.begin("engine task join", null)

        shouldThrow<IllegalStateException> { item.end() }

        work.count shouldBe 0
    }
}
