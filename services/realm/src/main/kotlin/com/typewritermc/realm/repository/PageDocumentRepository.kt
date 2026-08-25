package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.surrealdb.Value
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ReferenceAssembler
import com.typewritermc.elements.ReferenceAssemblyResult
import com.typewritermc.elements.StoredElement
import com.typewritermc.library.PageCompileStatus
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentDiagnostic
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageDocumentRevision
import com.typewritermc.library.PageId
import com.typewritermc.library.PageReference
import com.typewritermc.library.ResourceSummary
import com.typewritermc.library.ref
import com.typewritermc.realm.repository.records.ElementRecordParser
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import java.security.MessageDigest

interface PageDocumentRepository {
    suspend fun getPageDocument(pageId: PageId): PageDocument?

    suspend fun getAuthoringSnapshot(): AuthoringSnapshot

    suspend fun currentAuthoringRevision(): String

    suspend fun currentCollaborationRevision(): Long
}

data class AuthoringSnapshot(
    val revision: String,
    val documents: List<PageDocument>,
)

class SurrealPageDocumentRepository(
    private val database: Surreal,
    private val catalog: () -> PageDocumentCatalog?,
) : PageDocumentRepository {
    override suspend fun getPageDocument(pageId: PageId): PageDocument? =
        database.inTransaction { transaction -> load(transaction, pageId, catalog()) }

    override suspend fun getAuthoringSnapshot(): AuthoringSnapshot =
        database.inTransaction { transaction ->
            val revision = transaction.authoringRevision()
            val pageIds =
                transaction
                    .query("SELECT VALUE id FROM page ORDER BY id;")
                    .take(0)
                    .getArray()
                    .map { it.getRecordId().toPageId() }
            val resolvedCatalog = catalog()
            AuthoringSnapshot(revision, pageIds.mapNotNull { load(transaction, it, resolvedCatalog) })
        }

    override suspend fun currentAuthoringRevision(): String = database.inTransaction(Transaction::authoringRevision)

    override suspend fun currentCollaborationRevision(): Long =
        database.inTransaction { transaction ->
            transaction
                .query("SELECT VALUE revision FROM ONLY collaboration_head:current;")
                .take(0)
                .getLong()
        }

    private fun load(
        transaction: Transaction,
        pageId: PageId,
        catalog: PageDocumentCatalog?,
    ): PageDocument? {
        val source = loadSource(transaction, pageId) ?: return null
        val diagnostics = mutableListOf<PageDocumentDiagnostic>()
        val elements = source.elements.map { it.assemble(catalog, diagnostics) }
        val localIds = source.elements.mapTo(hashSetOf(), StoredElement::id)
        val localResourceIds = localIds.mapTo(hashSetOf(), ElementInstanceId::resourceId)
        val references =
            source.elements.flatMap { element ->
                element.value.references.map { reference ->
                    PageReference(element.id, reference.slot, reference.target, reference.expectedType)
                }
            }
        val targetIds = references.map(PageReference::target).distinct()
        val targetSummaries = loadSummaries(transaction, targetIds)
        val summariesById = targetSummaries.associateBy(ResourceSummary::id)
        references.forEach { reference ->
            if (reference.target !in summariesById) {
                diagnostics +=
                    PageDocumentDiagnostic(
                        code = "dangling-reference",
                        message = "Reference target ${reference.target.referenceString()} does not exist.",
                        element = reference.source,
                        slot = reference.slot,
                        target = reference.target,
                    )
            }
        }
        val crossPageTargets =
            targetIds
                .filterNot { it in localResourceIds }
                .map { id -> summariesById[id] ?: ResourceSummary(id, null, exists = false) }
        val reverseSourceIds = loadReverseSourceIds(transaction, localIds)
        val crossPageSources = loadSummaries(transaction, reverseSourceIds.map(ElementInstanceId::resourceId))
        val revision = documentRevision(source.page.revision.value, source.elements, references, targetSummaries)
        return PageDocument(
            revision = revision,
            page = source.page,
            elements = elements,
            references = references,
            crossPageTargets = crossPageTargets,
            crossPageSources = crossPageSources,
            diagnostics = diagnostics,
            compileStatus = loadCompileStatus(transaction, source.page.id, diagnostics.size),
        )
    }

    private fun loadCompileStatus(
        transaction: Transaction,
        pageId: PageId,
        diagnosticCount: Int,
    ): PageCompileStatus {
        val activeValue =
            transaction
                .query("SELECT VALUE manifest FROM ONLY active_compiled_manifest:current;")
                .take(0)
        val activeManifest =
            activeValue
                .takeUnless { it.isNone || it.isNull }
                ?.getRecordId()
                ?.id
                ?.string
        val attempt =
            transaction
                .query(
                    "SELECT status, source_revision, completed_at FROM compile_attempt " +
                        "WHERE pages CONTAINS \$page ORDER BY completed_at DESC LIMIT 1;",
                    mapOf("page" to pageId.surrealId()),
                ).take(0)
                .getArray()
                .firstOrNull()
                ?.getObject()
        val currentRevision = transaction.authoringRevision()
        if (
            attempt?.get("status")?.getString() == "blocked" &&
            attempt.get("source_revision").getString() == currentRevision
        ) {
            return PageCompileStatus.Blocked(activeManifest, diagnosticCount)
        }
        return activeManifest?.let { PageCompileStatus.Active(it) } ?: PageCompileStatus.NotCompiled
    }

    private fun loadSource(
        transaction: Transaction,
        pageId: PageId,
    ): PageDocumentSource? {
        val result =
            transaction
                .query(
                    "LET \$page = SELECT * FROM ONLY \$page_id; " +
                        "LET \$elements = SELECT * FROM element WHERE page = \$page_id ORDER BY id; " +
                        "LET \$references = SELECT * FROM element_reference WHERE in INSIDE \$elements.id ORDER BY in, slot; " +
                        "RETURN { page: \$page, elements: \$elements, references: \$references };",
                    mapOf("page_id" to pageId.surrealId()),
                ).takeTransaction(3)
                .getObject()
        val pageValue = result.get("page")
        if (pageValue.isNone || pageValue.isNull) return null
        val page = PageRecord.parseList(pageValue).single().toPage()
        val parsed = ElementRecordParser.parse(result.get("elements"), result.get("references"))
        return PageDocumentSource(page, parsed.elements)
    }

    private fun loadSummaries(
        transaction: Transaction,
        ids: Collection<ResourceId>,
    ): List<ResourceSummary> {
        if (ids.isEmpty()) return emptyList()
        return transaction
            .query(
                "SELECT id, name, title, element_type, page FROM \$targets ORDER BY id;",
                mapOf("targets" to ids.map(ResourceId::surrealId)),
            ).take(0)
            .getArray()
            .map(::parseSummary)
    }

    private fun loadReverseSourceIds(
        transaction: Transaction,
        localIds: Set<ElementInstanceId>,
    ): List<ElementInstanceId> {
        if (localIds.isEmpty()) return emptyList()
        return transaction
            .query(
                "SELECT VALUE in FROM element_reference WHERE out INSIDE \$targets AND in NOTINSIDE \$targets;",
                mapOf("targets" to localIds.map(ElementInstanceId::surrealId)),
            ).take(0)
            .getArray()
            .map { it.getRecordId().toElementInstanceId() }
            .distinct()
    }
}

private fun Transaction.authoringRevision(): String =
    query("SELECT VALUE revision FROM ONLY authoring_head:current;")
        .take(0)
        .getLong()
        .toString()

data class PageDocumentCatalog(
    val elements: ElementCatalog,
    val definitions: List<com.typewritermc.types.TypeDefinition>,
)

private data class PageDocumentSource(
    val page: com.typewritermc.library.Page,
    val elements: List<StoredElement>,
)

private fun StoredElement.assemble(
    catalog: PageDocumentCatalog?,
    diagnostics: MutableList<PageDocumentDiagnostic>,
): PageDocumentElement {
    val descriptor =
        catalog
            ?.elements
            ?.entries
            ?.singleOrNull { it.descriptor.id == elementType }
            ?.descriptor
    val logicalValue =
        if (descriptor == null) {
            diagnostics +=
                PageDocumentDiagnostic(
                    code = "element-type-unavailable",
                    message = "Element type ${elementType.value} is not available in the current catalog.",
                    element = id,
                )
            value.valueWithSlots
        } else {
            val graph = TypeGraph(TypeExpression.Named(descriptor.type), catalog.definitions)
            when (val assembled = ReferenceAssembler().assemble(graph, value)) {
                is ReferenceAssemblyResult.Success -> {
                    assembled.value
                }

                is ReferenceAssemblyResult.Failure -> {
                    diagnostics +=
                        assembled.diagnostics.map { diagnostic ->
                            PageDocumentDiagnostic(
                                code =
                                    diagnostic.code.name
                                        .lowercase()
                                        .replace('_', '-'),
                                message = "Reference assembly failed with ${diagnostic.code}.",
                                element = id,
                                slot = diagnostic.slot,
                                target = diagnostic.target,
                            )
                        }
                    assembled.value
                }
            }
        }
    return PageDocumentElement(id, revision, elementType, schemaRevision, name, logicalValue, placement)
}

private fun parseSummary(value: Value): ResourceSummary {
    val record = value.getObject()
    val id = record.get("id").getRecordId().toResourceId()
    val name = record.optionalString("name") ?: record.optionalString("title")
    val elementType =
        record.optionalString("element_type")?.let { com.typewritermc.elements.ElementTypeId(DeclaredTypeId.parse(it)) }
    val page =
        record
            .get("page")
            .takeUnless { it.isNone || it.isNull }
            ?.getRecordId()
            ?.toPageId()
            ?.ref()
    return ResourceSummary(id, name, elementType, page, exists = true)
}

private fun com.surrealdb.Object.optionalString(name: String): String? = get(name).optionalString()

private fun Value.optionalString(): String? = takeUnless { it.isNone || it.isNull }?.getString()

private fun ElementInstanceId.resourceId(): ResourceId = ResourceId("element", value.toHexString())

private fun documentRevision(
    pageRevision: Long,
    elements: List<StoredElement>,
    references: List<PageReference>,
    summaries: List<ResourceSummary>,
): PageDocumentRevision {
    val facts =
        buildString {
            append(pageRevision)
            elements.sortedBy { it.id.value.toHexString() }.forEach {
                append(
                    '|',
                ).append(it.id.value).append(':').append(it.revision.value)
            }
            references.sortedBy { "${it.source.value}:${it.slot.value}" }.forEach {
                append('|')
                    .append(it.source.value)
                    .append(':')
                    .append(it.slot.value)
                    .append(':')
                    .append(it.target.referenceString())
            }
            summaries.sortedBy { it.id.referenceString() }.forEach {
                append('|')
                    .append(it.id.referenceString())
                    .append(':')
                    .append(it.name)
                    .append(':')
                    .append(it.page?.id?.referenceString())
            }
        }
    val digest =
        MessageDigest.getInstance("SHA-256").digest(facts.toByteArray()).joinToString("") {
            "%02x".format(it.toInt() and 0xff)
        }
    return PageDocumentRevision(digest)
}
