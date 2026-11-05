package com.typewritermc.realm

import com.typewritermc.authoring.definition
import com.typewritermc.authoring.root
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.text
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.fixtureTimelinePage
import com.typewritermc.testkit.setup.SetupRejected
import com.typewritermc.types.items
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldStartWith

val SetupApplierTest by testSuite {
    val greeting =
        setup("greeting") {
            library {
                books.book("greeting") {
                    title = "Greeting"
                    pages.fixtureTimelinePage("start") { name = "Start" }
                    pages.fixtureTimelinePage("end") { name = "End" }
                    handle
                }
            }
        }

    test("a setup's resources are saved under their owners in builder order") {
        withSetup(greeting, RealmStorage.Surreal, routeFixtureCatalog) { book ->
            restart()

            val saved = resources.getValue(book.id.toSkir())
            saved.links("pages").map { resources.getValue(it).text("name") } shouldBe listOf("Start", "End")
            saved.link("library") shouldBe resources.filterValues { it.configuration.definition == LibraryDefinition.id }.keys.single()
        }
    }

    test("a refused setup names the setup path of the problem and saves nothing") {
        val loop = setup("loop") { taxonomy { tags.tag("loop") { parents = setOf(handle) } } }

        RealmFixture.core().use { realm ->
            val before = realm.resources

            val error = shouldThrow<SetupRejected> { realm.withSetup(loop) }

            error.problems.single() shouldStartWith "taxonomy / tags loop"
            error.problems.single() shouldContain "relation_cycle"
            realm.resources shouldBe before
        }
    }

    test("two setups that share a part create it once") {
        withSetup(greeting + greeting, catalog = routeFixtureCatalog) { _ ->
            resources.values.count { it.configuration.definition == BookDefinition.id } shouldBe 1
        }
    }
}
