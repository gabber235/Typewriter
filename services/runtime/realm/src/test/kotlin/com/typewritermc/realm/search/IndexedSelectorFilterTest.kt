package com.typewritermc.realm.search

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringSearchFacet
import com.typewritermc.authoring.AuthoringSearchSelector
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val IndexedSelectorFilterTest by testSuite {
    test("indexed search pages past incompatible candidates") {
        val parent = declaredType("11111111111111111111111111111111")
        val compatible = declaredType("22222222222222222222222222222222")
        val incompatible = declaredType("33333333333333333333333333333333")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(parent, NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(compatible, NominalTypeKind.CONCRETE, parents = listOf(parent)),
                    TypeDefinition(incompatible, NominalTypeKind.CONCRETE),
                ),
            )
        Surreal().use { database ->
            database.connect("memory")
            database.useNs("test").useDb("test")
            database.query(
                "DEFINE TABLE resource SCHEMALESS; " +
                    "DEFINE TABLE authoring_search SCHEMALESS; " +
                    "DEFINE TABLE authoring_search_selector SCHEMALESS;",
            )
            repeat(256) { index ->
                database.insertSearchRow("a-${index.toString().padStart(3, '0')}", incompatible)
            }
            database.insertSearchRow("z-compatible", compatible)

            val results =
                SurrealAuthoringSearchRepository(database) { catalog }.search(
                    query = "",
                    definitions = emptySet(),
                    contexts = emptySet(),
                    selectors = IndexedSelectorFilter.All,
                    assignableTo = TypeExpression.Named(parent),
                    limit = 100,
                )

            results.map { it.resource.value } shouldContainExactly listOf("z-compatible")
        }
    }

    test("negated selector filters require a bounded definition universe") {
        IndexedSelectorFilter
            .Not(
                IndexedSelectorFilter.Match("status", "draft"),
            ).requiresDefinitionUniverse shouldBe true
        IndexedSelectorFilter
            .And(
                IndexedSelectorFilter.Match("status", "draft"),
                IndexedSelectorFilter.Match("kind", "quest"),
            ).requiresDefinitionUniverse shouldBe false
    }

    test("selector record ids do not use the JVM hash collision domain") {
        selectorId(ResourceId("resource"), "status", "Aa") shouldNotBe
            selectorId(ResourceId("resource"), "status", "BB")
    }

    test("selector normalization follows each registered case sensitivity contract") {
        val metadata =
            AuthoringSearchMetadata(
                selectors =
                    listOf(
                        AuthoringSearchSelector("insensitive", "Insensitive"),
                        AuthoringSearchSelector("sensitive", "Sensitive", caseSensitive = true),
                    ),
                facets = listOf(AuthoringSearchFacet("group", "Group", "sensitive")),
            )

        metadata.normalize("insensitive", "  MixedCase  ") shouldBe "mixedcase"
        metadata.normalize("sensitive", "  MixedCase  ") shouldBe "MixedCase"
        metadata.selectorForFacet("group") shouldBe "sensitive"
    }
}

private fun Surreal.insertSearchRow(
    id: String,
    root: ResolvedTypeRef,
) {
    query(
        "CREATE ONLY \$search CONTENT { resource: \$resource, definition: 'test.resource', " +
            "root: \$root, text: '', owner_path: [] };",
        mapOf(
            "search" to RecordId("authoring_search", id),
            "resource" to RecordId("resource", id),
            "root" to StructuredDatabaseCodec.encode(ResolvedTypeRef.serializer(), root),
        ),
    ).take(0)
}

private fun declaredType(value: String): ResolvedTypeRef = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse(value)), 1)
