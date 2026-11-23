package com.typewritermc.realm.routes

import com.typewritermc.engine.pages.staticPage
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.setup.setup
import com.typewritermc.testkit.setup.SetupApplier
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

val RemoteSetupEditorTest by testSuite {
    val catalog = RealmCatalog(artifacts = listOf(RealmCatalog.engineCore))
    val loaded = listOf(RealmCatalog.typewriterApi, RealmCatalog.engineCore)
    val story =
        setup("story") {
            library { books.book("story") { pages.staticPage("start") { handle } } }
        }
    val other = setup("other") { library { books.book("other") { handle } } }

    test("a setup applied over the authoring routes is saved under its owners, and removing it leaves the realm as before") {
        RealmFixture.core(catalog = catalog).use { realm ->
            val before = realm.resources
            realm.withRemoteEditor(loaded) { editor ->
                SetupApplier(editor).apply(story)

                val page = realm.resources.getValue(story.handles.id.toSkir())
                realm.resources.getValue(page.link("book")).links("pages") shouldBe listOf(story.handles.id.toSkir())

                SetupApplier(editor).remove(story)
            }

            realm.resources shouldBe before
        }
    }

    test("a setup whose commit meets a change saved meanwhile is planned again on the saved state, and both are kept") {
        RealmFixture.core(catalog = catalog).use { realm ->
            realm.withRemoteEditor(loaded, beforeFirstCommit = { realm.withSetup(other) }) { editor ->
                SetupApplier(editor).apply(story)
            }

            val page = realm.resources.getValue(story.handles.id.toSkir())
            val library = realm.resources.getValue(realm.resources.getValue(page.link("book")).link("library"))
            library.links("books") shouldContainExactlyInAnyOrder listOf(other.handles.id.toSkir(), page.link("book"))
        }
    }

    test("the editor plans with the artifacts it is given, so a type only the running Realm loads is unknown to it") {
        RealmFixture.core(catalog = catalog).use { realm ->
            val before = realm.resources
            realm.withRemoteEditor(listOf(RealmCatalog.typewriterApi)) { editor ->
                shouldThrow<AssertionError> { SetupApplier(editor).apply(story) }.message shouldContain "unknown_definition"
            }

            realm.resources shouldBe before
        }
    }
}
