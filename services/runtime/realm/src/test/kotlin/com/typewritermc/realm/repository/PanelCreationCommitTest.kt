package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.schema.MigrationResources
import com.typewritermc.realm.schema.openTestDatabase
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.authoring.PreparedEdit as WireEdit
import skirout.editor.v1.catalog.EndpointDefinition as WireEndpoint

val PanelCreationCommitTest by testSuite {
    test("the panel page and Book creation commits into the Library through Realm and survives reload") {
        val snapshot = EditorCatalog.serializer.fromBytes(panelCreationFixture("catalog.skir"))
        val seed = SkirAuthoringOperationCodec.decode(WireEdit.serializer.fromBytes(panelCreationFixture("seed.skir"))).getOrThrow()
        val edit = SkirAuthoringOperationCodec.decode(WireEdit.serializer.fromBytes(panelCreationFixture("edit.skir"))).getOrThrow()
        val catalog = panelCreationCatalog(snapshot)
        Surreal().use { database ->
            database.openTestDatabase("panel_creation")
            MigrationResources().loadRealmSchema().forEach { database.query(it.script).take(0) }
            val storage = SurrealAuthoringStorage(database)
            val views = InMemoryAuthoringViewStore(catalog, storage.readCoherent())
            val owner = RealmAuthoringOwner(storage, views)
            owner.commit(seed) shouldBe CommitResult.Committed
            storage.readCoherent().resources.size shouldBe 1
            val broken =
                edit.copy(
                    intents =
                        edit.intents.map { intent ->
                            if (intent is EditIntent.ConnectRelation) {
                                intent.copy(intent = intent.intent.copy(target = ResourceId("absent")))
                            } else {
                                intent
                            }
                        },
                )
            owner.commit(broken).shouldBeInstanceOf<CommitResult.Rejected>()
            storage.readCoherent().resources.size shouldBe 1
            owner.commit(edit) shouldBe CommitResult.Committed
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
        generation = CatalogGeneration(snapshot.generation.value),
        definitions = snapshot.types.map { it.definition.requireValid() },
        relations =
            snapshot.relations.map { relation ->
                RelationContract(
                    RelationId(relation.id.value),
                    endpoint(relation.first),
                    endpoint(relation.second),
                    relation.families.mapTo(linkedSetOf()) { RelationFamilyId(it.value) },
                )
            },
        endpointBindings =
            snapshot.endpointBindings.map { binding ->
                EndpointBindingTemplate(
                    binding.endpoint.requireValid(),
                    binding.containingResource.requireValid(),
                    binding.valueOwner.requireValid(),
                    RelativeFieldPattern(
                        binding.relativePath.segments.map { segment ->
                            when (segment) {
                                is skirout.editor.v1.type_catalog.FieldPatternSegment.FieldWrapper -> {
                                    FieldPatternSegment.Field(segment.value.name)
                                }

                                skirout.editor.v1.type_catalog.FieldPatternSegment.ITEMS -> {
                                    FieldPatternSegment.Items
                                }

                                skirout.editor.v1.type_catalog.FieldPatternSegment.KEYS -> {
                                    FieldPatternSegment.Keys
                                }

                                skirout.editor.v1.type_catalog.FieldPatternSegment.VALUES -> {
                                    FieldPatternSegment.Values
                                }

                                else -> {
                                    error("Unknown captured field pattern")
                                }
                            }
                        },
                    ),
                    binding.target.requireValid(),
                    binding.containsCollection,
                )
            },
    )

private fun endpoint(endpoint: WireEndpoint): EndpointDefinition =
    EndpointDefinition(
        endpoint.id.requireValid(),
        when (endpoint.slot) {
            skirout.editor.v1.catalog.EndpointSlot.FIRST -> EndpointSlot.First
            skirout.editor.v1.catalog.EndpointSlot.SECOND -> EndpointSlot.Second
            else -> error("Unknown captured endpoint slot")
        },
        endpoint.resource.requireValid(),
        when (endpoint.cardinality) {
            skirout.editor.v1.catalog.EndpointCardinality.ONE -> EndpointCardinality.One
            skirout.editor.v1.catalog.EndpointCardinality.MANY -> EndpointCardinality.Many
            else -> error("Unknown captured endpoint cardinality")
        },
        when (endpoint.onDelete) {
            skirout.editor.v1.catalog.RelationDeletePolicy.RESTRICT -> RelationDeletePolicy.RESTRICT
            skirout.editor.v1.catalog.RelationDeletePolicy.CASCADE -> RelationDeletePolicy.CASCADE
            skirout.editor.v1.catalog.RelationDeletePolicy.CLEAR -> RelationDeletePolicy.CLEAR
            else -> error("Unknown captured deletion policy")
        },
    )
