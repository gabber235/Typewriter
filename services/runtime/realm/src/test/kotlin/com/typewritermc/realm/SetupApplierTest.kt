package com.typewritermc.realm

import com.typewritermc.authoring.definition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.fixtureTimelinePage
import com.typewritermc.testkit.setup.SetupRejected
import com.typewritermc.types.items
import com.typewritermc.types.toSkir
import com.typewritermc.types.unwrapNamed
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldStartWith
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.kernel.v1.resource_id.ResourceId

private val greeting =
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

val SetupApplierTest by testSuite {
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

private fun AuthoringRecord.text(field: String): String = (valueAt(field.path())?.unwrapNamed() as DataValue.StringValueWrapper).value

private fun AuthoringRecord.link(field: String): ResourceId =
    (valueAt(field.path())?.unwrapNamed() as DataValue.LinkWrapper).value.target.resource

private fun AuthoringRecord.links(field: String): List<ResourceId> =
    (valueAt(field.path())?.unwrapNamed() as DataValue.ListValueWrapper).items.map {
        (it.value.unwrapNamed() as DataValue.LinkWrapper).value.target.resource
    }

private fun String.path() =
    skirout.editor.v1.type_catalog.ValuePath.root
        .field(this)
