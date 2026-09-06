package com.typewritermc.library

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.Ref
import com.typewritermc.types.Referenceable
import com.typewritermc.types.ResourceId
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Groups authored pages under a stable identity and library name.
 *
 * Tags are references to separate records; constructing a book does not resolve them or enforce database
 * uniqueness.
 */
@Serializable
data class Book(
    val id: BookId,
    val title: LibraryName,
    val icon: Icon,
    val color: Color,
    val tags: Set<Ref<Tag>>,
) : Referenceable

/**
 * Represents a library tag with potentially multiple parents and editor placement.
 *
 * Hierarchy validation belongs to [TagHierarchy] and the repository. The record itself permits unresolved parent
 * references.
 */
@Serializable
data class Tag(
    val id: TagId,
    val name: LibraryName,
    val color: Color,
    val parents: Set<Ref<Tag>>,
    val placement: GridPlacement,
) : Referenceable

/**
 * Stores page metadata and its selected editor schema independently of element content.
 *
 * [PageDocument] adds elements, reference summaries, and diagnostics. The kind includes a revision so consumers
 * can detect incompatible schema changes.
 */
@Serializable
data class Page(
    val id: PageId,
    val book: Ref<Book>,
    val name: LibraryName,
    val kind: PageKindRef,
    val chapter: ChapterPath,
    val priority: Int,
) : Referenceable

@Serializable
data class GridPlacement(
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int,
)

/**
 * Provides the editor view of a page with logical element values and reference diagnostics.
 *
 * Element identities and source slot pairs must be unique. Cross page summaries may describe missing resources.
 * [compileStatus] reports publication state separately from whether the document can be edited.
 */
@Serializable
data class PageDocument(
    val page: Page,
    val elements: List<PageDocumentElement>,
    val references: List<PageReference>,
    val crossPageTargets: List<ResourceSummary>,
    val crossPageSources: List<ResourceSummary>,
    val diagnostics: List<PageDocumentDiagnostic>,
    val compileStatus: PageCompileStatus = PageCompileStatus.NotCompiled,
) {
    init {
        require(elements.map(PageDocumentElement::id).distinct().size == elements.size) {
            "Page document element ids must be unique."
        }
        require(references.map { it.source to it.slot }.distinct().size == references.size) {
            "Page document reference slots must be unique per source."
        }
    }
}

/**
 * Carries an editor element with assembled logical values rather than persistence slot markers.
 *
 * The schema revision identifies the shape of [value]; consult document diagnostics before treating it as valid
 * compiled content.
 */
@Serializable
data class PageDocumentElement(
    val id: ElementInstanceId,
    val elementType: ElementTypeId,
    val schemaRevision: Int,
    val name: String,
    val value: DataValue,
    val placement: ElementPlacement,
)

@Serializable
data class PageReference(
    val source: ElementInstanceId,
    val slot: ReferenceSlotId,
    val target: ResourceId,
    val expectedType: com.typewritermc.types.TypeExpression,
)

/**
 * Describes a referenced resource without loading its full document.
 *
 * [exists] distinguishes missing targets, while optional name, element type, and page fields supply context when
 * known.
 */
@Serializable
data class ResourceSummary(
    val id: ResourceId,
    val name: String?,
    val elementType: ElementTypeId? = null,
    val page: Ref<Page>? = null,
    val exists: Boolean,
)

@Serializable
data class PageDocumentDiagnostic(
    val code: String,
    val message: String,
    val element: ElementInstanceId? = null,
    val slot: ReferenceSlotId? = null,
    val target: ResourceId? = null,
)

/**
 * Reports whether the current authored page has usable compiled content.
 *
 * A blocked page may retain a previously active manifest. Consumers must not interpret that manifest as proof that
 * the latest authoring revision compiled successfully.
 */
@Serializable
sealed interface PageCompileStatus {
    @Serializable
    @SerialName("not_compiled")
    data object NotCompiled : PageCompileStatus

    @Serializable
    @SerialName("active")
    data class Active(
        val manifestId: String,
    ) : PageCompileStatus

    @Serializable
    @SerialName("blocked")
    data class Blocked(
        val lastActiveManifestId: String?,
        val diagnosticCount: Int,
    ) : PageCompileStatus
}
