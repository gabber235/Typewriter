package com.typewritermc.engine.paper

import com.typewritermc.engine.pages.staticPage
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.testSuite
import kotlin.time.Duration.Companion.minutes

val StackAuthorRequirements by testSuite(
    compartment = { GameCompartment },
    testConfig =
        TestConfig.aroundAll { requirements ->
            StackObserver.fromEnvironment().use { it.awaitActive("game_paper_0", 3.minutes) }
            requirements()
        },
) {
    requirement(
        "AUTHOR-1",
        "content a requirement owns is the stack Realm's current publication and live on Paper when its body runs",
        content =
            listOf(
                content("author-1") { copy ->
                    library {
                        books.book(copy.book) {
                            title = copy.book
                            pages.staticPage("start") { }
                        }
                    }
                },
            ),
    ) {
        val written = content.single().live.present
        player.quit()
        player.rejoin()
        within(20.ticks) {
            state("the stack Realm's current publication compiles the attempt's book") {
                StackAuthor.shared().publishedRoots().containsAll(written)
            }
        }
    }
}
