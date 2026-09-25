package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val StructuredRootPersistenceTest by testSuite {
    test("schemafull Realm stores Book and nested type roots as objects") {
        val bookRoot =
            ResolvedTypeRef(
                TypeId.Declared(DeclaredTypeId.parse("bbb646b300cf4dd2b7aab051854e4dd1")),
                revision = 1,
            )
        val genericRoot =
            bookRoot.withArguments(
                listOf(TypeExpression.Named(ResolvedTypeRef(TypeId.Qualified("example", "Item"), 2))),
            )
        val bookId = ResourceId("book")
        val genericId = ResourceId("generic")
        val resources =
            listOf(bookId to bookRoot, genericId to genericRoot).associate { (id, root) ->
                id to
                    DecomposedResourceValue(
                        StoredTypedResource(
                            id = id,
                            definition = ResourceDefinitionId("typewriter.book"),
                            root = root,
                            valueWithSlots = DataValue.Record(emptyMap()),
                        ),
                        emptyList(),
                    )
            }

        val telemetry = TelemetryTestHarness.create()
        try {
            Surreal().use { database ->
                database.connect("memory")
                database.useNs("structured_root_test").useDb("structured_root_test")
                telemetry.telemetry.mainSpanBlocking(
                    name = "test.realm.start",
                    unhandledFailureSlug = ErrorSlug.of("test-realm-start-failed"),
                ) {
                    SchemaMigrator(database).migrate()
                }

                database.inTransaction { transaction ->
                    SurrealResourceGraphStore().apply(
                        transaction,
                        AuthoringGraphDelta(
                            resourceUpserts = resources,
                            resourceCreates = resources.keys,
                            resourceRemovals = emptySet(),
                            relationUpserts = emptyMap(),
                            relationRemovals = emptySet(),
                        ),
                    )
                }

                val rows = database.query("SELECT * FROM resource ORDER BY id;").take(0).getArray()
                rows.len() shouldBe 2
                val stored = rows.toList().associateBy { parseStoredResource(it).id }
                val bookRow = stored.getValue(bookId)
                bookRow.getObject().get("root").isObject shouldBe true
                parseStoredResource(bookRow).root shouldBe bookRoot

                val genericRow = stored.getValue(genericId)
                val nested =
                    genericRow.getObject().get("root").getObject()
                        .get("arguments").getArray().get(0).getObject().get("reference")
                nested.isObject shouldBe true
                parseStoredResource(genericRow).root shouldBe genericRoot

                database.query(
                    "CREATE ONLY authoring_search:generic CONTENT " +
                        "{ resource: \$resource, definition: \$definition, root: \$root, text: \$text, owner_path: \$owner_path };",
                    mapOf(
                        "resource" to genericId.unifiedSurrealId(),
                        "definition" to "typewriter.book",
                        "root" to StructuredDatabaseCodec.encode(ResolvedTypeRef.serializer(), genericRoot),
                        "text" to "Book",
                        "owner_path" to emptyList<String>(),
                    ),
                ).take(0)
                val searchRoot =
                    database.query("SELECT root FROM authoring_search;").take(0).getArray().get(0)
                        .getObject().get("root")
                searchRoot.isObject shouldBe true
                StructuredDatabaseCodec.decode(ResolvedTypeRef.serializer(), searchRoot) shouldBe genericRoot
            }
        } finally {
            telemetry.close()
        }
    }
}
