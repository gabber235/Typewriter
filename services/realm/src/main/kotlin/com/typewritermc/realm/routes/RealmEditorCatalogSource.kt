package com.typewritermc.realm.routes

import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.elements.ElementCatalogEntry
import com.typewritermc.pages.PageCatalogEntry
import com.typewritermc.pages.PageDiagnostic
import com.typewritermc.pages.ResolvedPageEditorDefinition
import com.typewritermc.presentation.PresentationDiagnostic
import com.typewritermc.realm.RealmDiscoverySnapshot
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.PresentationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.capability.CommandCapabilityDefinition
import skirout.editor.v1.capability.ComputationCapabilityDefinition
import skirout.editor.v1.capability.SearchCapabilityDefinition
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.SubtypeResult
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.TypeDiagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CapabilityId as SkirCapabilityId

interface RealmEditorCatalogSource {
    suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult

    suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate
}

class SnapshotRealmEditorCatalogSource(
    private val snapshot: suspend () -> RealmDiscoverySnapshot?,
) : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult {
        val snapshot = snapshot() ?: return unavailableCatalogFetchResult("Realm discovery snapshot is unavailable")
        val generation = snapshot.discovery.generation.value
        if (request.expectedGeneration?.value != null && request.expectedGeneration?.value != generation) {
            return CatalogFetchResult.createGenerationMismatch(actualGeneration = CatalogGeneration(value = generation))
        }
        val requestedTypes = request.requestedTypes.map { SkirTypeCodec.decode(it).getOrThrow() }
        val subtypeMatches =
            request.subtypeQueries.map { query ->
                val target = SkirTypeCodec.decode(query.target).getOrThrow()
                Triple(query.queryId, target, snapshot.discovery.types.subtypesOf(target))
            }
        val subtypeResults =
            subtypeMatches.map { (queryId, _, matches) ->
                SubtypeResult(
                    queryId = queryId,
                    matchingTypes = matches.map { SkirTypeCodec.encode(it.id).getOrThrow() },
                )
            }
        val closure =
            snapshot.closure(
                requestedTypes +
                    snapshot.catalogTypes() +
                    subtypeMatches.flatMap { (_, target, matches) -> listOf(target) + matches.map { it.id } },
                request.presentationIds.map { PresentationId(it.namespace, it.name) },
            )
        val encoded = SkirTypeCodec.encode(closure.types).getOrThrow()
        return CatalogFetchResult.createSuccess(
            generation = CatalogGeneration(value = generation),
            typeDefinitions = encoded.definitions,
            presentationDefinitions = closure.presentations,
            conversions = emptyList(),
            capabilityDefinitions = closure.capabilities.map(RealmCapabilityDescriptor::toWire),
            subtypeResults = subtypeResults,
            diagnostics = snapshot.presentationDiagnostics.map(PresentationDiagnostic::toWire),
            elementEntries = snapshot.elements.entries.map(ElementCatalogEntry::toSkir),
            pageEntries = snapshot.pages.entries.map(PageCatalogEntry::toSkir),
            pageDiagnostics = snapshot.pages.diagnostics.map(PageDiagnostic::toSkir),
        )
    }

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(
            value = snapshot()?.discovery?.generation?.value ?: "unavailable",
        )
}

private fun RealmDiscoverySnapshot.catalogTypes(): List<ResolvedTypeRef> =
    elements.entries.map { it.descriptor.type } +
        pages.entries.flatMap { entry ->
            when (val editor = entry.descriptor.editor) {
                is ResolvedPageEditorDefinition.Graph -> editor.nodes
                is ResolvedPageEditorDefinition.Timeline -> editor.tracks + editor.segments + editor.keyframes
            }
        }

private data class RealmEditorCatalogClosure(
    val types: TypeCatalog,
    val presentations: List<skirout.editor.v1.presentation.PresentationDefinition>,
    val capabilities: List<RealmCapabilityDescriptor>,
)

private fun RealmDiscoverySnapshot.closure(
    requestedTypes: List<ResolvedTypeRef>,
    requestedPresentations: List<PresentationId>,
): RealmEditorCatalogClosure {
    val collector = TypeClosureCollector(discovery.types)
    requestedTypes.forEach(collector::includeReference)
    val presentationsById =
        presentations.associateBy { PresentationId(it.presentationId.namespace, it.presentationId.name) }
    val capabilitiesById = capabilities.associateBy(RealmCapabilityDescriptor::id)
    val presentationIds = requestedPresentations.toMutableSet()
    val capabilityIds = mutableSetOf<CapabilityId>()
    var previousTypeCount = -1
    var previousPresentationCount = -1
    var previousCapabilityCount = -1
    while (
        previousTypeCount != collector.definitions.size ||
        previousPresentationCount != presentationIds.size ||
        previousCapabilityCount != capabilityIds.size
    ) {
        previousTypeCount = collector.definitions.size
        previousPresentationCount = presentationIds.size
        previousCapabilityCount = capabilityIds.size
        presentationIds.apply {
            collector.definitions.forEach { definition ->
                definition.defaultPresentationId?.let(::add)
                addAll(definition.namedPresentations.values)
            }
        }
        presentationIds.mapNotNull(presentationsById::get).forEach { presentation ->
            collector.includeExpression(SkirTypeCodec.decode(presentation.target).getOrThrow())
            presentation.dependencies.types.forEach { collector.includeReference(SkirTypeCodec.decode(it).getOrThrow()) }
            presentation.dependencies.presentations.forEach { presentationIds += PresentationId(it.namespace, it.name) }
            presentation.dependencies.capabilities.forEach { capabilityIds += CapabilityId(it.value) }
        }
        capabilityIds.mapNotNull(capabilitiesById::get).forEach { capability ->
            collector.includeReference(capability.requestType)
            when (capability) {
                is RealmCapabilityDescriptor.Search -> collector.includeReference(capability.resultType)
                is RealmCapabilityDescriptor.Computation -> collector.includeReference(capability.resultType)
                is RealmCapabilityDescriptor.Command -> Unit
            }
        }
    }
    return RealmEditorCatalogClosure(
        types = TypeCatalog(collector.definitions),
        presentations = presentationIds.mapNotNull(presentationsById::get),
        capabilities = capabilityIds.mapNotNull(capabilitiesById::get),
    )
}

private fun RealmCapabilityDescriptor.toWire(): CapabilityDefinition =
    when (this) {
        is RealmCapabilityDescriptor.Search -> {
            CapabilityDefinition.SearchWrapper(
                SearchCapabilityDefinition(
                    capabilityId = SkirCapabilityId(value = id.value),
                    requestType = SkirTypeCodec.encode(requestType).getOrThrow(),
                    resultType = SkirTypeCodec.encode(resultType).getOrThrow(),
                ),
            )
        }

        is RealmCapabilityDescriptor.Computation -> {
            CapabilityDefinition.ComputationWrapper(
                ComputationCapabilityDefinition(
                    capabilityId = SkirCapabilityId(value = id.value),
                    requestType = SkirTypeCodec.encode(requestType).getOrThrow(),
                    resultType = SkirTypeCodec.encode(resultType).getOrThrow(),
                ),
            )
        }

        is RealmCapabilityDescriptor.Command -> {
            CapabilityDefinition.CommandWrapper(
                CommandCapabilityDefinition(
                    capabilityId = SkirCapabilityId(value = id.value),
                    requestType = SkirTypeCodec.encode(requestType).getOrThrow(),
                ),
            )
        }
    }

private class TypeClosureCollector(
    private val catalog: TypeCatalog,
) {
    private val definitionsById = catalog.definitions.associateBy { it.id }
    private val included = linkedMapOf<ResolvedTypeRef, TypeDefinition>()

    val definitions: List<TypeDefinition>
        get() = included.values.toList()

    fun includeReference(reference: ResolvedTypeRef) {
        reference.arguments.forEach(::includeExpression)
        definitionsById[reference.copy(arguments = emptyList())]?.let(::includeDefinition)
    }

    fun includeExpression(expression: TypeExpression) {
        when (expression) {
            TypeExpression.Any,
            TypeExpression.Boolean,
            TypeExpression.Unit,
            is TypeExpression.Bytes,
            is TypeExpression.Decimal,
            is TypeExpression.Duration,
            is TypeExpression.Float,
            is TypeExpression.Integer,
            is TypeExpression.Parameter,
            is TypeExpression.StringType,
            is TypeExpression.Timestamp,
            -> {
                return
            }

            is TypeExpression.Enumeration -> {
                includeExpression(expression.valueType)
            }

            is TypeExpression.ListType -> {
                includeExpression(expression.element)
            }

            is TypeExpression.MapType -> {
                includeExpression(expression.key)
                includeExpression(expression.value)
            }

            is TypeExpression.Record -> {
                expression.fields.forEach { includeExpression(it.type) }
            }

            is TypeExpression.Named -> {
                includeReference(expression.reference)
            }
        }
    }

    private fun includeDefinition(definition: TypeDefinition) {
        if (included.putIfAbsent(definition.id, definition) != null) return
        includeExpression(definition.representation)
        definition.parameters.flatMap { it.upperBounds }.forEach(::includeExpression)
        definition.parents.forEach(::includeReference)
        if (definition.kind != NominalTypeKind.CONCRETE) {
            catalog.subtypesOf(definition.id).forEach(::includeDefinition)
        }
    }
}

class UnavailableRealmEditorCatalogSource : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult =
        CatalogFetchResult.UnavailableWrapper(listOf(unavailableDiagnostic()))

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(value = "unavailable")
}

internal fun unavailableCatalogFetchResult(message: String): CatalogFetchResult =
    CatalogFetchResult.UnavailableWrapper(listOf(unavailableDiagnostic(message)))

private fun unavailableDiagnostic(message: String = "Realm editor catalog source is unavailable"): TypeDiagnostic =
    TypeDiagnostic(
        code = DiagnosticCode.INVALID_PRESENTATION,
        severity = DiagnosticSeverity.ERROR,
        message = message,
        path = null,
        relatedType = null,
        details = emptyList(),
    )

private fun PresentationDiagnostic.toWire(): TypeDiagnostic =
    TypeDiagnostic(
        code = DiagnosticCode.INVALID_PRESENTATION,
        severity = DiagnosticSeverity.WARNING,
        message =
            buildString {
                append(message)
                namespace?.let { append(" Namespace: $it.") }
                sourcePart?.let { append(" Source part: $it.") }
                presentationName?.let { append(" Presentation: $it.") }
            },
        path = null,
        relatedType = null,
        details = emptyList(),
    )
