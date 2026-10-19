package com.typewritermc.realm.compiler

import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.descendants
import com.typewritermc.engine.CompilationContext
import com.typewritermc.engine.CompiledEdge
import com.typewritermc.engine.CompiledEdgeOrigin
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledResource
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PAGE_COMPILATION_FORMAT_REVISION
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.engine.RuntimeCompilationFacts
import com.typewritermc.engine.RuntimeRelationFact
import com.typewritermc.engine.canonicalized
import com.typewritermc.engine.semanticDigest
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.DataValue
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.runtimeDefinitions

/**
 * Compiles a Page and its ownership closure from one assessed authoring view.
 *
 * The shard includes scalar resource records, native binding evidence, incident relation edges, and the
 * runtime declaration closure. Edges may refer outside the shard so the engine can assemble the complete
 * publication graph. The input fingerprint identifies captured authoring inputs; the shard semantic digest
 * identifies canonical runtime facts and is separate from its serialized blob digest.
 */
internal class PageCompiler(
    private val ownershipRelations: Set<RelationId>,
    private val readiness: Map<ResourceId, ResourceReadiness>,
    private val formatRevision: Int = PAGE_COMPILATION_FORMAT_REVISION,
) {
    context(snapshot: AuthoringView)
    fun compile(root: ResourceId): PageCompileResult {
        val projected = snapshot.projection
        val occurrencesByLocation = snapshot.links.values.associateBy { it.id.location }
        val relationByEndpoint =
            snapshot.catalog.relations
                .flatMap { relation ->
                    listOf(relation.first.id to relation.id, relation.second.id to relation.id)
                }.toMap()
        val ownershipEndpoints =
            snapshot.catalog.relations
                .filter { it.id in ownershipRelations }
                .flatMap { relation ->
                    listOf(
                        relation.first.id to com.typewritermc.types.EndpointSlot.First,
                        relation.second.id to com.typewritermc.types.EndpointSlot.Second,
                    )
                }.groupBy({ it.first }, { it.second })
        val childrenByOwner =
            snapshot.links.values
                .flatMap { occurrence ->
                    ownershipEndpoints[occurrence.id.endpoint].orEmpty().map { slot ->
                        when (slot) {
                            com.typewritermc.types.EndpointSlot.First -> occurrence.source to occurrence.target.resource
                            com.typewritermc.types.EndpointSlot.Second -> occurrence.target.resource to occurrence.source
                        }
                    }
                }.groupBy({ it.first }, { it.second })
        val owned = linkedSetOf(root)
        val pending = ArrayDeque<ResourceId>()
        pending += root
        val diagnostics = mutableListOf<com.typewritermc.checking.Diagnostic>()
        while (pending.isNotEmpty()) {
            childrenByOwner[pending.removeFirst()].orEmpty().forEach { child ->
                if (child in snapshot.resources && owned.add(child)) pending += child
            }
        }
        diagnostics +=
            projected.problems
                .filter { problem ->
                    problem.location.resource in owned || occurrencesByLocation[problem.location]?.target?.resource in owned
                }.map { problem ->
                    val occurrence = occurrencesByLocation[problem.location]
                    val missingOwned =
                        problem.code == "target_resource_missing" &&
                            occurrence != null &&
                            relationByEndpoint[occurrence.id.endpoint] in ownershipRelations
                    compilationDiagnostic(
                        code = if (missingOwned) "missing_owned_resource" else problem.code,
                        message =
                            if (missingOwned) {
                                "Owned resource ${occurrence.target.resource.value} is absent from the captured snapshot."
                            } else {
                                "Captured link projection is invalid at ${problem.location}."
                            },
                        severity = com.typewritermc.checking.DiagnosticSeverity.Error,
                        source = occurrence?.source ?: problem.location.resource,
                        location = problem.location,
                        target = occurrence?.target?.resource,
                    )
                }
        val projectedEdges =
            projected.projections
                .filter { projection -> projection.first in owned || projection.second in owned }
                .map { projection ->
                    CompiledEdge(
                        source = CompiledResourceKey(projection.first, CompilationContext.Root),
                        target = CompiledResourceKey(projection.second, CompilationContext.Root),
                        origin =
                            CompiledEdgeOrigin.Relation(
                                projection.contract,
                                projection.firstLocation,
                                projection.secondLocation,
                            ),
                    )
                }
        val resources = owned.mapNotNull { id -> snapshot.resources[id]?.let { id to it } }.sortedBy { it.first.value }
        resources.forEach { (id, record) ->
            if (id !in snapshot.resourceDefinitions) {
                diagnostics +=
                    compilationDiagnostic(
                        "missing_resource_definition",
                        "Resource ${id.value} has no captured resource definition identity.",
                        source = id,
                    )
            }
            when (val state = readiness.getValue(id)) {
                is ResourceReadiness.Blocked -> {
                    diagnostics += state.findings
                }

                is ResourceReadiness.Ready -> {
                    check(state.value.schema.catalog == snapshot.catalog.generation) {
                        "Resource readiness belongs to another captured catalog."
                    }
                    val actual =
                        (record.configuration as? TypeSelection.Complete)?.use ?: error("Ready resource has a pending configuration.")
                    check(actual == state.binding.actual && state.value.value == DataValue.Named(actual, DataValue.Record(record.fields))) {
                        "Resource readiness belongs to another captured value."
                    }
                }
            }
        }

        val fingerprint =
            digest(
                buildString {
                    append("format:").append(formatRevision)
                    append("|catalog:").append(snapshot.catalog.generation.value)
                    append("|root:").append(root.value)
                    resources.forEach { (id, record) -> append("|resource:").append(id.value).append(':').append(record) }
                    projectedEdges.sortedWith(compareBy({ it.source.source.value }, { it.target.source.value })).forEach { edge ->
                        append("|edge:").append(edge)
                    }
                },
            )
        if (diagnostics.isNotEmpty()) return PageCompileResult.Blocked(fingerprint, diagnostics.distinctBy { it.id })
        val runtimeResources = resources.map { (id, record) -> record.compile(id, (readiness.getValue(id) as ResourceReadiness.Ready)) }
        val relationIds =
            projectedEdges.mapTo(linkedSetOf()) { edge ->
                (edge.origin as CompiledEdgeOrigin.Relation).relation
            }
        val facts =
            RuntimeCompilationFacts(
                formatRevision = formatRevision,
                root = CompiledResourceKey(root, CompilationContext.Root),
                resources = runtimeResources,
                edges = projectedEdges,
                types =
                    snapshot.catalog.checked.runtimeDefinitions(
                        runtimeResources.flatMap { resource ->
                            resource.value
                                .descendants()
                                .mapNotNull { located ->
                                    (located.value as? DataValue.Named)?.actualType
                                }.toList()
                        },
                    ),
                relations =
                    snapshot.catalog.relations
                        .filter { relation -> relation.id in relationIds }
                        .map { relation ->
                            RuntimeRelationFact(
                                relation.id,
                                RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in relation.families,
                            )
                        },
            )
        val canonical = facts.canonicalized()
        return PageCompileResult.Success(
            shard = CompiledPageShard(canonical.semanticDigest(), canonical),
            inputFingerprint = fingerprint,
        )
    }
}

context(snapshot: AuthoringView)
private fun com.typewritermc.authoring.AuthoringRecord.compile(
    id: ResourceId,
    readiness: ResourceReadiness.Ready,
): CompiledResource {
    val actual = (configuration as TypeSelection.Complete).use
    val definition = requireNotNull(snapshot.resourceDefinitions[id])
    val binding = readiness.binding
    return CompiledResource(
        key = CompiledResourceKey(id, CompilationContext.Root),
        definition = definition,
        actualType = actual,
        bindingProvider = binding.provider,
        bindingSignature = binding.signature,
        value = readiness.value.value as DataValue.Named,
    )
}

private fun digest(value: String): ContentDigest = ContentDigest(value.sha256Hex())

internal fun compilationDiagnostic(
    code: String,
    message: String,
    severity: com.typewritermc.checking.DiagnosticSeverity = com.typewritermc.checking.DiagnosticSeverity.Error,
    source: ResourceId? = null,
    target: ResourceId? = null,
    location: com.typewritermc.authoring.ValueLocation? =
        source?.let {
            com.typewritermc.authoring.ValueLocation(it, com.typewritermc.authoring.ValuePath())
        },
): com.typewritermc.checking.Diagnostic =
    com.typewritermc.checking.Diagnostic(
        com.typewritermc.authoring.DiagnosticId("publication:compiler:$location:${target?.value}:$code"),
        com.typewritermc.configuration.RuleOrigin(
            com.typewritermc.types.TypeDefinitionId(
                com.typewritermc.types.TypeId
                    .Qualified("typewriter", "publication"),
                1,
            ),
            0,
        ),
        code,
        message,
        severity,
        location,
        target?.let { listOf(com.typewritermc.authoring.ValueLocation(it, com.typewritermc.authoring.ValuePath())) }.orEmpty(),
    )
