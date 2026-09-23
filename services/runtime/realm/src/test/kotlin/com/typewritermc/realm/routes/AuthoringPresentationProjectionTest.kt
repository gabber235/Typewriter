package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringPresentationSubject
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypedValueEnvelope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val AuthoringPresentationProjectionTest by testSuite {
    test("presentation projections receive only their declared graph slice") {
        val definition = ResourceDefinitionId("example.extension_resource")
        val root = ResolvedTypeRef(TypeId.Qualified("example", "ExtensionResource"), 1)
        val resource = resource(ResourceId("extension"), definition, root)
        val related = resource(ResourceId("configuration"), definition, root)
        val graph =
            AuthoringWorkingGraph(
                resources =
                    mapOf(
                        resource.id to resource.toStored(),
                        related.id to related.toStored(),
                    ),
                relations = emptyMap(),
            )
        val registry =
            AuthoringPresentationRegistry(
                mapOf(
                    definition to
                        object : AuthoringPresentationProjection {
                            override fun project(
                                resource: AuthoringGraphResource,
                                graph: AuthoringWorkingGraph,
                            ) = AuthoringPresentationSubject(
                                resource = resource.id,
                                definition = resource.definition,
                                content = resource.content,
                                descriptor =
                                    ResourceTypeDescriptor(
                                        (resource.content.rootType as TypeExpression.Named).reference,
                                        "resources:${graph.resources.size}",
                                        "",
                                        Icon.Iconify("material-symbols:description"),
                                        com.typewritermc.types.Color(0xff607d8bu),
                                    ),
                            )
                        },
                ),
            )

        registry.project(resource, graph).descriptor.name shouldBe "resources:1"
    }
}

private fun resource(
    id: ResourceId,
    definition: ResourceDefinitionId,
    root: ResolvedTypeRef,
) = AuthoringGraphResource(
    id = id,
    definition = definition,
    content = TypedValueEnvelope(TypeExpression.Named(root), DataValue.Record(emptyMap())),
)

private fun AuthoringGraphResource.toStored() =
    StoredTypedResource(
        id = id,
        definition = definition,
        root = (content.rootType as TypeExpression.Named).reference,
        valueWithSlots = content.rootValue,
    )
