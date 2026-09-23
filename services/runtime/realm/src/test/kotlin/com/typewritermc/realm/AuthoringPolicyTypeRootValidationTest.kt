package com.typewritermc.realm

import com.typewritermc.authoring.AuthoringChangeSummary
import com.typewritermc.authoring.AuthoringCompilationProjection
import com.typewritermc.authoring.AuthoringCompilationProjectionId
import com.typewritermc.authoring.AuthoringCompilationResult
import com.typewritermc.authoring.AuthoringCompilationRoot
import com.typewritermc.authoring.AuthoringPolicyProvider
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.AuthoringWorkingGraph
import com.typewritermc.authoring.GraphReadRequirement
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.types.DataValue
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import com.typewritermc.realm.repository.AuthoringWorkingGraph as RealmWorkingGraph

val AuthoringPolicyTypeRootValidationTest by testSuite {
    test("derives initial compilation scope and roots from the registered root type") {
        val rootType = ResolvedTypeRef(TypeId.Qualified("fixture", "Compiled"), 1)
        val definition = ResourceDefinitionId("fixture.resource")
        val projectionId = AuthoringCompilationProjectionId("fixture.compile")
        val provider =
            AuthoringPolicyProvider { builder ->
                builder.definition(
                    AuthoringResourceDefinition(
                        definition,
                        TypeExpression.Named(rootType),
                    ),
                )
                builder.compilation(
                    object : AuthoringCompilationProjection {
                        override val id = projectionId
                        override val root = TypeExpression.Named(rootType)
                        override val graphRequirement = GraphReadRequirement()

                        override fun affectedRoots(
                            change: AuthoringChangeSummary,
                            before: AuthoringWorkingGraph,
                            proposed: AuthoringWorkingGraph,
                        ): Set<ResourceId> = emptySet()

                        override suspend fun compile(
                            root: ResourceId,
                            graph: AuthoringWorkingGraph,
                        ): AuthoringCompilationResult =
                            AuthoringCompilationResult.Removed(
                                AuthoringCompilationRoot(id, root),
                            )
                    },
                )
            }
        val types =
            TypeCatalog(
                listOf(TypeDefinition(rootType, NominalTypeKind.CONCRETE, TypeExpression.Record(emptyList()))),
            )

        val projection =
            RealmAuthoringPolicyAssembler
                .assemble(listOf(provider), types)
                .compilation.projections
                .single()
        val resource = ResourceId("compiled")
        val graph =
            RealmWorkingGraph(
                resources =
                    mapOf(
                        resource to StoredTypedResource(resource, definition, rootType, DataValue.Record(emptyMap())),
                    ),
                relations = emptyMap(),
            )

        projection.graphRequirement.definitions shouldBe setOf(definition)
        projection.roots(graph) shouldBe setOf(resource)
    }

    test("rejects a resource root absent from the type catalog") {
        val root = ResolvedTypeRef(TypeId.Qualified("fixture", "Missing"), 1)
        val provider =
            AuthoringPolicyProvider { builder ->
                builder.definition(
                    AuthoringResourceDefinition(
                        ResourceDefinitionId("fixture.resource"),
                        TypeExpression.Named(root),
                    ),
                )
            }

        shouldThrow<IllegalArgumentException> {
            RealmAuthoringPolicyAssembler.assemble(listOf(provider), TypeCatalog(emptyList()))
        }
    }

    test("rejects a compilation root absent from the type catalog") {
        val knownRoot = ResolvedTypeRef(TypeId.Qualified("fixture", "Known"), 1)
        val missingRoot = ResolvedTypeRef(TypeId.Qualified("fixture", "Missing"), 1)
        val provider =
            AuthoringPolicyProvider { builder ->
                builder.definition(
                    AuthoringResourceDefinition(
                        ResourceDefinitionId("fixture.resource"),
                        TypeExpression.Named(knownRoot),
                    ),
                )
                builder.compilation(
                    object : AuthoringCompilationProjection {
                        override val id = AuthoringCompilationProjectionId("fixture.compile")
                        override val root = TypeExpression.Named(missingRoot)
                        override val graphRequirement = GraphReadRequirement()

                        override fun affectedRoots(
                            change: AuthoringChangeSummary,
                            before: AuthoringWorkingGraph,
                            proposed: AuthoringWorkingGraph,
                        ): Set<ResourceId> = emptySet()

                        override suspend fun compile(
                            root: ResourceId,
                            graph: AuthoringWorkingGraph,
                        ): AuthoringCompilationResult =
                            AuthoringCompilationResult.Removed(
                                AuthoringCompilationRoot(id, root),
                            )
                    },
                )
            }
        val types =
            TypeCatalog(
                listOf(TypeDefinition(knownRoot, NominalTypeKind.CONCRETE, TypeExpression.Any)),
            )

        shouldThrow<IllegalArgumentException> {
            RealmAuthoringPolicyAssembler.assemble(listOf(provider), types)
        }
    }
}
