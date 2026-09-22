package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringChangeSummary
import com.typewritermc.authoring.AuthoringPresentationSubject
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry

/** Projects one hydrated resource through Realm owned catalog metadata. */
internal interface AuthoringPresentationProjection {
    fun project(
        resource: AuthoringGraphResource,
        graph: AuthoringWorkingGraph,
    ): AuthoringPresentationSubject

    fun affectedResources(
        change: AuthoringChangeSummary,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> = change.changedResources
}

/** Resolves optional presentation adapters by open resource definition. */
internal class AuthoringPresentationRegistry(
    projections: Map<ResourceDefinitionId, AuthoringPresentationProjection>,
) {
    private val projections = projections.toMap()

    fun project(
        resource: AuthoringGraphResource,
        graph: AuthoringWorkingGraph,
    ): AuthoringPresentationSubject = projections[resource.definition]?.project(resource, graph) ?: resource.genericSubject(graph)

    fun affectedResources(
        change: AuthoringChangeSummary,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> =
        projections.values.flatMapTo(linkedSetOf()) { projection ->
            projection.affectedResources(change, before, proposed)
        }
}

/** Projects one hydrated resource without classifying unknown definitions as a core family. */
internal class AuthoringPresentationProjector(
    private val prototypes: TypePrototypeRegistry,
    private val presentations: AuthoringPresentationRegistry,
) {
    fun <T : Any> encode(value: T) = prototypes.encode(value).toWire()

    fun toWire(subject: AuthoringPresentationSubject) =
        skirout.editor.v1.authoring.PresentationSubject(
            content = subject.content.toWire(),
            descriptor = prototypes.encode(subject.descriptor).toWire(),
            identity = prototypes.encode(subject.identity).toWire(),
            resource = subject.resource.toWire(),
            definition = subject.definition.toWire(),
            ownerPath = subject.ownerPath.map(ResourceId::toWire),
        )

    fun project(
        resource: AuthoringGraphResource,
        ownerPath: List<ResourceId>? = null,
        graph: AuthoringWorkingGraph = AuthoringWorkingGraph(emptyMap(), emptyMap()),
    ): AuthoringPresentationSubject =
        presentations.project(resource, graph).let { subject ->
            if (ownerPath == null) subject else subject.copy(ownerPath = ownerPath)
        }

    fun affectedResources(
        change: AuthoringChangeSummary,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> = presentations.affectedResources(change, before, proposed)
}

private val AuthoringGraphResource.root: com.typewritermc.types.ResolvedTypeRef
    get() = (content.rootType as TypeExpression.Named).reference

private fun AuthoringGraphResource.descriptor(
    name: String,
    description: String,
    icon: String,
    color: UInt,
): ResourceTypeDescriptor = ResourceTypeDescriptor(root, name, description, Icon.Iconify(icon), Color(color))

private fun AuthoringGraphResource.genericSubject(graph: AuthoringWorkingGraph): AuthoringPresentationSubject {
    val ownerPath = graph.ownerPath(id)
    return AuthoringPresentationSubject(
        resource = id,
        definition = definition,
        content = content,
        descriptor =
            descriptor(
                name = root.id.toString().substringAfterLast('.'),
                description = definition.value,
                icon = "material-symbols:description-outline",
                color = 0xff607d8bu,
            ),
        ownerPath = ownerPath,
    )
}

private fun AuthoringWorkingGraph.ownerPath(resource: ResourceId): List<ResourceId> =
    generateSequence(resource) { current ->
        relations.values
            .firstOrNull { relation ->
                relation.target == current && relation.origin is com.typewritermc.realm.repository.ResourceRelationOrigin.Declared
            }?.source
    }.drop(1).toList()
