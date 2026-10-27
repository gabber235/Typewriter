package com.typewritermc.realm.edit

import com.typewritermc.authoring.requireValid
import com.typewritermc.authoring.text
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.linkedPairs
import com.typewritermc.realm.testing.panelCreationCatalog
import com.typewritermc.realm.testing.panelCreationFixture
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.types.requireValid
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.EditorCatalog
import skirout.kernel.v1.resource_id.ResourceId
import skirout.editor.v1.authoring.PreparedEdit as WireEdit

/** The seeded Library the panel creates into. */
private const val LIBRARY = "library:existing"

val PanelCreationCommitTest by testSuite {
    val snapshot = EditorCatalog.serializer.fromBytes(panelCreationFixture("catalog.skir"))

    val library = WireEdit.serializer.fromBytes(panelCreationFixture("seed.skir")).requireValid()

    val creation = WireEdit.serializer.fromBytes(panelCreationFixture("edit.skir")).requireValid()

    /** The Book the edit creates: the resource whose back reference it connects to the Library. */
    val book =
        creation.intents
            .filterIsInstance<EditIntent.ConnectRelationWrapper>()
            .map { it.value }
            .single { it.target.value == LIBRARY }
            .source.id.location.resource.value

    /** The page the edit creates in that Book. */
    val page =
        creation.intents
            .filterIsInstance<EditIntent.CreateResourceWrapper>()
            .map { it.value.id.value }
            .single { it != book }

    /** The item the edit inserts into the Library's Books for the created Book, such as `books[item]`. */
    val bookItemPath =
        creation.intents
            .filterIsInstance<EditIntent.InsertWrapper>()
            .map { it.value }
            .single { it.at.resource.value == LIBRARY }
            .let { "${it.at.path.text}[${it.item.id.value}]" }

    /** The Library owns the Book and the Book owns its page, each linked from both sides. */
    val createdPairs = setOf(LIBRARY to book, book to LIBRARY, book to page, page to book)

    test("the panel page and Book creation commits into the Library through Realm and survives reload") {
        RealmFixture.surreal(panelCreationCatalog(snapshot)).use { realm ->
            realm.commit(library.copy(catalog = realm.generation)).shouldBeCommitted()

            realm.commit(creation.copy(catalog = realm.generation)).shouldBeCommitted()
            val saved = realm.resources
            realm.restart()

            realm.resources shouldBe saved
            realm.linkedPairs() shouldBe createdPairs
        }
    }

    test("a creation connecting to a missing resource is refused at the connect location and saves nothing") {
        RealmFixture.surreal(panelCreationCatalog(snapshot)).use { realm ->
            realm.commit(library.copy(catalog = realm.generation)).shouldBeCommitted()
            val saved = realm.resources
            val broken =
                creation.copy(
                    catalog = realm.generation,
                    intents =
                        creation.intents.map { intent ->
                            if (intent is EditIntent.ConnectRelationWrapper) {
                                EditIntent.ConnectRelationWrapper(intent.value.copy(target = ResourceId(value = "absent")))
                            } else {
                                intent
                            }
                        },
                )

            realm.commit(broken).shouldBeRejected().map { Triple(it.location.resource.value, it.location.path.text, it.code) } shouldBe
                listOf(Triple(LIBRARY, bookItemPath, "counterpart_resource_mismatch"))
            realm.restart()
            realm.resources shouldBe saved
        }
    }
}
