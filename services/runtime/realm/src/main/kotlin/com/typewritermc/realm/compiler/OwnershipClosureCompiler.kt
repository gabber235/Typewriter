package com.typewritermc.realm.compiler

import com.typewritermc.authoring.CompilationUnitDefinition
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.descendants
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.root
import com.typewritermc.authoring.text
import com.typewritermc.authoring.use
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION
import com.typewritermc.engine.ResourceGraphCompileResult
import com.typewritermc.engine.Root
import com.typewritermc.engine.canonicalized
import com.typewritermc.engine.dataValue
import com.typewritermc.engine.relation
import com.typewritermc.engine.semanticDigest
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.runtimeDefinitions
import com.typewritermc.types.endpoint
import com.typewritermc.types.named
import com.typewritermc.types.ownsResources
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledEdge
import skirout.editor.v1.compiled_content.CompiledEdgeOrigin
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.ResourceGraphShard
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.compiled_content.RuntimeRelationFact
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation

/**
 * Compiles a compilation unit and its ownership closure from one assessed authoring view.
 *
 * The closure stops at nested compilation units: each is its own shard, reached from this one through an edge.
 * The shard includes scalar resource records, native binding evidence, incident relation edges, and the
 * runtime declaration closure. Edges may refer outside the shard so the engine can assemble the complete
 * publication graph. The input fingerprint identifies captured authoring inputs; the shard semantic digest
 * identifies canonical runtime facts and is separate from its serialized blob digest.
 */
internal class OwnershipClosureCompiler(
    private val ownershipRelations: Set<RelationId>,
    private val readiness: Map<ResourceId, ResourceReadiness>,
    private val formatRevision: Int = RESOURCE_GRAPH_FORMAT_REVISION,
) {
    context(snapshot: AuthoringView)
    fun compile(root: ResourceId): ResourceGraphCompileResult {
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
                        relation.first.id to EndpointSlot.FIRST,
                        relation.second.id to EndpointSlot.SECOND,
                    )
                }.groupBy({ it.first }, { it.second })
        val childrenByOwner =
            snapshot.links.values
                .flatMap { occurrence ->
                    ownershipEndpoints[occurrence.id.endpoint].orEmpty().map { slot ->
                        when (slot) {
                            EndpointSlot.FIRST -> occurrence.source.toResourceId() to occurrence.target.resource.toResourceId()
                            EndpointSlot.SECOND -> occurrence.target.resource.toResourceId() to occurrence.source.toResourceId()
                            else -> unknownVariant(slot)
                        }
                    }
                }.groupBy({ it.first }, { it.second })
        val owned = linkedSetOf(root)
        val pending = ArrayDeque<ResourceId>()
        pending += root
        val diagnostics = mutableListOf<Diagnostic>()
        // A nested compilation unit is compiled as its own shard, so the closure ends at its root.
        while (pending.isNotEmpty()) {
            childrenByOwner[pending.removeFirst()].orEmpty().forEach { child ->
                if (child in snapshot.resources && !child.isCompilationUnit() && owned.add(child)) pending += child
            }
        }
        diagnostics +=
            projected.problems
                .filter { problem ->
                    problem.location.resource.toResourceId() in owned ||
                        occurrencesByLocation[problem.location]?.target?.resource?.toResourceId() in owned
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
                                "Captured link projection is invalid at ${problem.location.resource.value} ${problem.location.path.text}."
                            },
                        severity = DiagnosticSeverity.ERROR,
                        source = occurrence?.source?.toResourceId() ?: problem.location.resource.toResourceId(),
                        location = problem.location,
                        target = occurrence?.target?.resource?.toResourceId(),
                    )
                }
        val projectedEdges =
            projected.projections
                .filter { projection -> projection.first in owned || projection.second in owned }
                .map { projection ->
                    CompiledEdge(
                        source = CompiledResourceKey(source = projection.first.toSkir(), context = CompilationContext.Root),
                        target = CompiledResourceKey(source = projection.second.toSkir(), context = CompilationContext.Root),
                        origin =
                            CompiledEdgeOrigin.createRelation(
                                relation = projection.contract,
                                firstLocation = projection.firstLocation,
                                secondLocation = projection.secondLocation,
                            ),
                    )
                }
        val resources = owned.mapNotNull { id -> snapshot.resources[id]?.let { id to it } }.sortedBy { it.first.value }
        resources.forEach { (id, record) ->
            when (val state = readiness.getValue(id)) {
                is ResourceReadiness.Blocked -> {
                    diagnostics += state.findings
                }

                is ResourceReadiness.Ready -> {
                    check(state.value.schema.catalog == snapshot.catalog.generation) {
                        "Resource readiness belongs to another captured catalog."
                    }
                    val actual =
                        (record.configuration as? TypeSelection.CompleteWrapper)?.use
                            ?: error("Ready resource has a pending configuration.")
                    check(
                        actual == state.binding.actual &&
                            state.value.value == DataValue.named(actual, DataValue.RecordWrapper(record.payload)),
                    ) {
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
                    resources.forEach { (id, record) ->
                        append("|resource:").append(id.value).append(':').append(AuthoringRecord.serializer.toJsonCode(record))
                    }
                    projectedEdges.sortedWith(compareBy({ it.source.source.value }, { it.target.source.value })).forEach { edge ->
                        append("|edge:").append(CompiledEdge.serializer.toJsonCode(edge))
                    }
                },
            )
        if (diagnostics.isNotEmpty()) return ResourceGraphCompileResult.Blocked(fingerprint, diagnostics.distinctBy { it.id })
        val runtimeResources = resources.map { (id, record) -> record.compile(id, (readiness.getValue(id) as ResourceReadiness.Ready)) }
        val relationIds =
            projectedEdges.mapTo(linkedSetOf()) { edge ->
                edge.relation
            }
        val facts =
            RuntimeCompilationFacts(
                formatRevision = formatRevision,
                root = CompiledResourceKey(source = root.toSkir(), context = CompilationContext.Root),
                resources = runtimeResources,
                edges = projectedEdges,
                types =
                    snapshot.catalog.checked.runtimeDefinitions(
                        runtimeResources.flatMap { resource ->
                            resource.dataValue
                                .descendants()
                                .mapNotNull { located ->
                                    (located.value as? DataValue.NamedWrapper)?.actualType?.use
                                }.toList()
                        },
                    ),
                relations =
                    snapshot.catalog.relations
                        .filter { relation -> relation.id in relationIds }
                        .map { relation ->
                            RuntimeRelationFact(
                                relation = relation.id,
                                ownsResources = relation.ownsResources,
                            )
                        },
            )
        val canonical = facts.canonicalized()
        return ResourceGraphCompileResult.Success(
            shard = ResourceGraphShard(digest = canonical.semanticDigest().value, facts = canonical),
            inputFingerprint = fingerprint,
        )
    }
}

/** Whether this resource is a complete compilation unit, which the resource graph producer compiles as a root. */
context(snapshot: AuthoringView)
internal fun ResourceId.isCompilationUnit(): Boolean = snapshot.resources[this]?.isCompilationUnit(snapshot.catalog.checked) == true

/** Whether this record is a complete compilation unit, which the resource graph producer compiles as a root. */
internal fun AuthoringRecord.isCompilationUnit(catalog: CheckedCatalog): Boolean {
    val selection = configuration as? TypeSelection.CompleteWrapper ?: return false
    return catalog.isNominalSubtype(selection.use.definition, CompilationUnitDefinition.id)
}

context(snapshot: AuthoringView)
private fun AuthoringRecord.compile(
    id: ResourceId,
    readiness: ResourceReadiness.Ready,
): CompiledResource {
    val actual = (configuration as TypeSelection.CompleteWrapper).use
    val binding = readiness.binding
    return CompiledResource(
        key = CompiledResourceKey(source = id.toSkir(), context = CompilationContext.Root),
        actualType = actual,
        bindingProvider = binding.provider,
        bindingSignature = binding.signature,
        value = (readiness.value.value as DataValue.NamedWrapper).value,
    )
}

private fun digest(value: String): ContentDigest = ContentDigest(value.sha256Hex())

internal fun compilationDiagnostic(
    code: String,
    message: String,
    severity: DiagnosticSeverity = DiagnosticSeverity.ERROR,
    source: ResourceId? = null,
    target: ResourceId? = null,
    location: ValueLocation? =
        source?.let {
            ValueLocation.of(it)
        },
): Diagnostic =
    Diagnostic(
        id = DiagnosticId(value = "publication:compiler:${location?.let(ValueLocation.serializer::toJsonCode)}:${target?.value}:$code"),
        origin = RuleOrigin(owner = PUBLICATION_DIAGNOSTIC_TYPE, ordinal = 0),
        code = code,
        message = message,
        severity = severity,
        primary = location,
        related = target?.let { listOf(ValueLocation.of(it)) }.orEmpty(),
    )
