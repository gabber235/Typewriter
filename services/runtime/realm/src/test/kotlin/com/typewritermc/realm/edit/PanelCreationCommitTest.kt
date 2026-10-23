package com.typewritermc.realm.edit

import com.surrealdb.Surreal
import com.typewritermc.authoring.requireValid
import com.typewritermc.configuration.name
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.storage.MigrationResources
import com.typewritermc.realm.storage.openTestDatabase
import com.typewritermc.types.of
import com.typewritermc.types.requireValid
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.authoring.PreparedEdit as WireEdit
import skirout.editor.v1.catalog.EndpointDefinition as WireEndpoint

val PanelCreationCommitTest by testSuite {
    test("the panel page and Book creation commits into the Library through Realm and survives reload") {
        val snapshot = EditorCatalog.serializer.fromBytes(panelCreationFixture("catalog.skir"))
        val seed = WireEdit.serializer.fromBytes(panelCreationFixture("seed.skir")).requireValid()
        val edit = WireEdit.serializer.fromBytes(panelCreationFixture("edit.skir")).requireValid()
        val catalog = panelCreationCatalog(snapshot)
        Surreal().use { database ->
            database.openTestDatabase("panel_creation")
            MigrationResources().loadRealmSchema().forEach { database.query(it.script).take(0) }
            val storage = SurrealAuthoringStorage(database)
            val views = InMemoryAuthoringViewStore(catalog, storage.readCoherent())
            val owner = RealmAuthoringOwner(storage, views)
            owner.commit(seed) shouldBe CommitPreparedEditResponse.COMMITTED
            storage.readCoherent().resources.size shouldBe 1
            val broken =
                edit.copy(
                    intents =
                        edit.intents.map { intent ->
                            if (intent is EditIntent.ConnectRelationWrapper) {
                                EditIntent.ConnectRelationWrapper(intent.value.copy(target = ResourceId(value = "absent")))
                            } else {
                                intent
                            }
                        },
                )
            owner.commit(broken).shouldBeInstanceOf<CommitPreparedEditResponse.RejectedErrorWrapper>()
            storage.readCoherent().resources.size shouldBe 1
            owner.commit(edit) shouldBe CommitPreparedEditResponse.COMMITTED
            val saved = storage.readCoherent()
            saved.resources.size shouldBe 3
            val links =
                ResourceValueMapper.project(
                    ResourceValueMapper.discover(saved.resources),
                    saved.resources,
                    catalog.relations,
                    catalog.checked,
                )
            links.problems shouldBe emptyList()
            links.projections.size shouldBe 2
            links.projections.all { it.firstLocation != null && it.secondLocation != null } shouldBe true
            database
                .query("SELECT * FROM resource_relation;")
                .take(0)
                .getArray()
                .len() shouldBe 2
            views.close()
            val restarted = InMemoryAuthoringViewStore(panelCreationCatalog(snapshot), saved)
            restarted.capture().use { it.root.resources shouldBe saved.resources }
            restarted.close()
        }
    }
}

private fun panelCreationFixture(name: String): ByteArray =
    requireNotNull(TestCatalogLease::class.java.getResourceAsStream("/creation/$name")) {
        "Missing panel creation fixture $name. Capture it by running resource_creation_flow_test.dart with " +
            "TYPEWRITER_CREATION_FIXTURE_DIR set to this resource directory."
    }.use { it.readBytes() }

/** The captured panel catalog: a Library owning Books that own pages, each linking back to its owner. */
private fun panelCreationCatalog(snapshot: EditorCatalog): TestCatalogLease =
    TestCatalogLease(
        generation = snapshot.generation,
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
