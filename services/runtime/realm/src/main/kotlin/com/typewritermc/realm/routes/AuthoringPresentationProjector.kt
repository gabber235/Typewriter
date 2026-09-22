package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringChangeSummary
import com.typewritermc.authoring.AuthoringPresentationSubject
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.PolicyGraphSliceResult
import com.typewritermc.realm.repository.sliceForPolicy
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry

/** Projects one hydrated resource through Realm owned catalog metadata. */
internal interface AuthoringPresentationProjection {
    val graphRequirement: GraphReadRequirement
        get() = GraphReadRequirement()

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

    fun graphRequirement(definition: ResourceDefinitionId): GraphReadRequirement =
        projections[definition]?.graphRequirement ?: GraphReadRequirement()

    fun project(
        resource: AuthoringGraphResource,
        graph: AuthoringWorkingGraph,
    ): AuthoringPresentationSubject {
        val projection = projections[resource.definition] ?: return resource.genericSubject()
        val bounded = graph.requirePolicySlice(setOf(resource.id), projection.graphRequirement, resource.definition.value)
        return projection.project(resource, bounded)
    }

    fun affectedResources(
        change: AuthoringChangeSummary,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> =
        projections.values.flatMapTo(linkedSetOf()) { projection ->
            val roots = change.policyRoots(before, proposed)
            projection.affectedResources(
                change,
                before.requirePolicySlice(roots, projection.graphRequirement, "presentation"),
                proposed.requirePolicySlice(roots, projection.graphRequirement, "presentation"),
            )
        }
}

private fun AuthoringChangeSummary.policyRoots(
    before: AuthoringWorkingGraph,
    proposed: AuthoringWorkingGraph,
): Set<ResourceId> =
    buildSet {
        addAll(changedResources)
        changedEdges.forEach { edgeId ->
            listOfNotNull(before.relations[edgeId], proposed.relations[edgeId]).forEach { relation ->
                add(relation.source)
                add(relation.target)
            }
        }
    }

private fun AuthoringWorkingGraph.requirePolicySlice(
    roots: Set<ResourceId>,
    requirement: GraphReadRequirement,
    owner: String,
): AuthoringWorkingGraph =
    when (val result = sliceForPolicy(roots, requirement)) {
        is PolicyGraphSliceResult.Success -> {
            result.graph
        }

        is PolicyGraphSliceResult.LimitExceeded -> {
            error("$owner exceeded its graph ${result.dimension} limit ${result.limit}.")
        }
    }

/** Projects one hydrated resource without classifying unknown definitions as a core family. */
internal class AuthoringPresentationProjector(
    private val prototypes: TypePrototypeRegistry,
    private val presentations: AuthoringPresentationRegistry,
) {
    fun graphRequirement(definition: ResourceDefinitionId): GraphReadRequirement = presentations.graphRequirement(definition)

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

private fun AuthoringGraphResource.genericSubject(): AuthoringPresentationSubject =
    AuthoringPresentationSubject(
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
        ownerPath = emptyList(),
    )
