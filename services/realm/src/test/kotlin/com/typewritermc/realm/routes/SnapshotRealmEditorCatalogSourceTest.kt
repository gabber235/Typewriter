package com.typewritermc.realm.routes

import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeId
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.SubtypeQuery
import skirout.editor.v1.catalog.SubtypeQueryId
import com.typewritermc.discovery.CatalogGeneration as DiscoveryGeneration

val SnapshotRealmEditorCatalogSourceTest by testSuite {
    test("successful fetch returns the complete generation catalog") {
        val fixture = catalogFixture()
        val source = SnapshotRealmEditorCatalogSource { fixture.snapshot }
        val request =
            emptyRequest(
                requestedTypes = listOf(SkirTypeCodec.encode(fixture.leaf.id).getOrThrow()),
            )

        val response = source.fetch(request) as CatalogFetchResult.SuccessWrapper

        response.value.typeDefinitions.size shouldBe fixture.snapshot.types.definitions.size
    }

    test("subtype queries retain abstract and concrete descendants") {
        val fixture = catalogFixture()
        val source = SnapshotRealmEditorCatalogSource { fixture.snapshot }
        val response =
            source.fetch(
                emptyRequest(
                    subtypeQueries =
                        listOf(
                            SubtypeQuery(
                                queryId = SubtypeQueryId(value = "descendants"),
                                target = SkirTypeCodec.encode(fixture.parent.id).getOrThrow(),
                            ),
                        ),
                ),
            ) as CatalogFetchResult.SuccessWrapper

        response.value.subtypeResults
            .single()
            .matchingTypes
            .map { SkirTypeCodec.decode(it).getOrThrow() }
            .toSet() shouldBe setOf(fixture.middle.id, fixture.leaf.id)
    }
}

private data class CatalogFixture(
    val parent: TypeDefinition,
    val middle: TypeDefinition,
    val leaf: TypeDefinition,
    val snapshot: DeploymentDiscoverySnapshot,
)

private fun catalogFixture(): CatalogFixture {
    val parent = definition("Parent", NominalTypeKind.OPEN_ABSTRACT)
    val middle = definition("Middle", NominalTypeKind.OPEN_ABSTRACT, listOf(parent.id))
    val leaf = definition("Leaf", NominalTypeKind.CONCRETE, listOf(middle.id))
    return CatalogFixture(
        parent = parent,
        middle = middle,
        leaf = leaf,
        snapshot =
            DeploymentDiscoverySnapshot(
                generation = DiscoveryGeneration("generation"),
                artifacts = emptyList(),
                sourceParts = emptyList(),
                types = TypeCatalog(listOf(leaf, parent, middle)),
                diagnostics = emptyList(),
            ),
    )
}

private fun definition(
    name: String,
    kind: NominalTypeKind,
    parents: List<ResolvedTypeRef> = emptyList(),
): TypeDefinition =
    TypeDefinition(
        id = ResolvedTypeRef(TypeId.Qualified("test", name), revision = 1),
        kind = kind,
        parents = parents,
    )

private fun emptyRequest(
    requestedTypes: List<skirout.editor.v1.type_catalog.ResolvedTypeRef> = emptyList(),
    subtypeQueries: List<SubtypeQuery> = emptyList(),
): CatalogFetchRequest =
    CatalogFetchRequest(
        expectedGeneration = null,
        requestedTypes = requestedTypes,
        presentationIds = emptyList(),
        conversionIds = emptyList(),
        realmActionIds = emptyList(),
        subtypeQueries = subtypeQueries,
    )
