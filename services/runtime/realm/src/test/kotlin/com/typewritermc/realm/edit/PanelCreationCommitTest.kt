package com.typewritermc.realm.edit

import com.typewritermc.authoring.requireValid
import com.typewritermc.authoring.text
import com.typewritermc.configuration.name
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.types.of
import com.typewritermc.types.requireValid
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.kernel.v1.resource_id.ResourceId
import skirout.editor.v1.authoring.PreparedEdit as WireEdit
import skirout.editor.v1.catalog.EndpointDefinition as WireEndpoint

private val snapshot = EditorCatalog.serializer.fromBytes(panelCreationFixture("catalog.skir"))
private val library = WireEdit.serializer.fromBytes(panelCreationFixture("seed.skir")).requireValid()
private val creation = WireEdit.serializer.fromBytes(panelCreationFixture("edit.skir")).requireValid()

val PanelCreationCommitTest by testSuite {
    test("the panel page and Book creation commits into the Library through Realm and survives reload") {
        RealmFixture.surreal(panelCreationCatalog(snapshot)).use { realm ->
            realm.commit(library.copy(catalog = realm.generation)).shouldBeCommitted()

            realm.commit(creation.copy(catalog = realm.generation)).shouldBeCommitted()
            val saved = realm.resources
            realm.restart()

            realm.resources shouldBe saved
            realm.linkedPairs() shouldBe CREATED_PAIRS
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
                listOf(Triple(LIBRARY, "books[$BOOK_ITEM]", "counterpart_resource_mismatch"))
            realm.restart()
            realm.resources shouldBe saved
        }
    }
}

/** Each saved link as its source and target, read from the Realm's derived links. */
private fun RealmFixture.linkedPairs(): Set<Pair<String, String>> =
    views.read { view ->
        view.links.values.mapTo(sortedSetOf(compareBy({ it.first }, { it.second }))) {
            it.source.value to
                it.target.resource.value
        }
    }

/** The ids the captured panel edits use: the seeded Library, the created Book, its item in the Library and its page. */
private const val LIBRARY = "library:existing"
private const val BOOK = "gnze6ml8o1dbb2vmnz9l"
private const val BOOK_ITEM = "panel:reference:6ea90175-01a9-4f74-8286-ae3b34447e55"
private const val PAGE = "b0jxtk4z55j1z2t7tggb"

/** The Library owns the Book and the Book owns its page, each linked from both sides. */
private val CREATED_PAIRS = setOf(LIBRARY to BOOK, BOOK to LIBRARY, BOOK to PAGE, PAGE to BOOK)

private fun panelCreationFixture(name: String): ByteArray =
    requireNotNull(TestCatalogLease::class.java.getResourceAsStream("/creation/$name")) {
        "Missing panel creation fixture $name. Capture it by running resource_creation_flow_test.dart with " +
            "TYPEWRITER_CREATION_FIXTURE_DIR set to this resource directory."
    }.use { it.readBytes() }

/** The captured panel catalog: a Library owning Books that own pages, each linking back to its owner. */
private fun panelCreationCatalog(snapshot: EditorCatalog) =
    DefinitionCatalog(
        definitions = snapshot.types.map { it.definition.requireValid() },
        relations =
            snapshot.relations.map { relation ->
                RelationContract.of(
                    relation.id,
                    endpoint(relation.first),
                    endpoint(relation.second),
                    relation.families.toSet(),
                )
            },
    )

private fun endpoint(endpoint: WireEndpoint): EndpointDefinition =
    EndpointDefinition(
        id = endpoint.id.requireValid(),
        slot =
            when (endpoint.slot) {
                skirout.editor.v1.catalog.EndpointSlot.FIRST -> EndpointSlot.FIRST
                skirout.editor.v1.catalog.EndpointSlot.SECOND -> EndpointSlot.SECOND
                else -> error("Unknown captured endpoint slot")
            },
        resource = endpoint.resource.requireValid(),
        cardinality =
            when (endpoint.cardinality) {
                skirout.editor.v1.catalog.EndpointCardinality.ONE -> EndpointCardinality.ONE
                skirout.editor.v1.catalog.EndpointCardinality.MANY -> EndpointCardinality.MANY
                else -> error("Unknown captured endpoint cardinality")
            },
        onDelete =
            when (endpoint.onDelete) {
                skirout.editor.v1.catalog.RelationDeletePolicy.RESTRICT -> RelationDeletePolicy.RESTRICT
                skirout.editor.v1.catalog.RelationDeletePolicy.CASCADE -> RelationDeletePolicy.CASCADE
                skirout.editor.v1.catalog.RelationDeletePolicy.CLEAR -> RelationDeletePolicy.CLEAR
                else -> error("Unknown captured deletion policy")
            },
    )
