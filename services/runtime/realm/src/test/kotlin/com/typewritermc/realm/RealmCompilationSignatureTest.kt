package com.typewritermc.realm

import com.typewritermc.discovery.CatalogGeneration
import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.discovery.ResolvedDeploymentTypes
import com.typewritermc.discovery.ResolvedType
import com.typewritermc.discovery.TypeMetadata
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RealmCompilationSignatureTest by testSuite {
    test("editor metadata and generation do not change the compilation signature") {
        val id = ResolvedTypeRef(TypeId.Qualified("test", "Resource"), 1)
        val definition = TypeDefinition(id, NominalTypeKind.CONCRETE)
        val first = snapshot(definition, null, "first")
        val second = snapshot(definition.copy(displayName = "Renamed"), TypeMetadata(id), "second")

        first.compilationSignature() shouldBe second.compilationSignature()
    }

    test("a structural field change changes the compilation signature") {
        val id = ResolvedTypeRef(TypeId.Qualified("test", "Resource"), 1)
        val definition = TypeDefinition(id, NominalTypeKind.CONCRETE)
        val changed = definition.copy(representation = TypeExpression.StringType())

        (snapshot(definition, null, "first").compilationSignature() ==
            snapshot(changed, null, "first").compilationSignature()) shouldBe false
    }
}

private fun snapshot(definition: TypeDefinition, metadata: TypeMetadata?, generation: String): RealmDiscoverySnapshot =
    RealmDiscoverySnapshot(
        discovery = DeploymentDiscoverySnapshot(
            generation = CatalogGeneration(generation),
            artifacts = emptyList(),
            sourceParts = emptyList(),
            types = TypeCatalog(listOf(definition)),
            diagnostics = emptyList(),
        ),
        types = ResolvedDeploymentTypes(
            typesById = mapOf(
                definition.id to ResolvedType(definition, metadata, emptyMap(), emptySet()),
            ),
            relations = emptyList(),
            prototypeBindings = emptyList(),
            executableBindings = emptyList(),
        ),
    )
