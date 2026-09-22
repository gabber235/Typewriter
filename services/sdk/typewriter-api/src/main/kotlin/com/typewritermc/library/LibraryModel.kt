package com.typewritermc.library

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.Placement
import com.typewritermc.authoring.ReferenceResourceResolution
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.Ref
import com.typewritermc.types.Referenceable
import com.typewritermc.types.Relation
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ToMany
import com.typewritermc.types.ToOne
import com.typewritermc.types.TypewriterRelation
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Groups authored pages under a stable identity and library name.
 *
 * Tags are references to separate records; constructing a book does not resolve them or enforce database
 * uniqueness.
 */
@TypewriterType(id = "bbb646b300cf4dd2b7aab051854e4dd1")
data class Book(
    val title: String = "",
    val icon: Icon = Icon.Iconify("material-symbols:book"),
    val color: Color = Color(0xff3f51b5u),
    val tags: Set<Ref<Tag>> = emptySet(),
    val pages: ToMany<BookPages, Page> = ToMany.empty(),
) : Referenceable

/** Owns the synchronized Book to Page containment relationship. */
@TypewriterRelation(
    id = BOOK_PAGES_RELATION_ID,
    onSourceDelete = RelationDeletePolicy.CASCADE,
    onTargetDelete = RelationDeletePolicy.CLEAR,
)
sealed interface BookPages : Relation<Book, Page>

/**
 * Represents a library tag with potentially multiple parents and editor placement.
 *
 * Hierarchy validation belongs to [TagHierarchy] and the repository. The record itself permits unresolved parent
 * references.
 */
@TypewriterType(id = "ce1ae253a42d4509935c48b8ecba664a")
data class Tag(
    val name: String = "",
    val color: Color = Color(0xff9e9e9eu),
    val parents: Set<Ref<Tag>> = emptySet(),
    val placement: GraphPlacement,
) : Referenceable

/**
 * Stores page metadata and its selected editor schema independently of element content.
 *
 * [PageDocument] adds elements, reference summaries, and diagnostics. The kind includes a revision so consumers
 * can detect incompatible schema changes.
 */
@TypewriterType(id = "2f5ff6a1077d41a4be6d527e864c1409")
data class Page(
    val book: ToOne<BookPages, Book>,
    val name: String = "",
    val kind: PageKindRef,
    val chapter: ChapterPath,
    val priority: Int,
    val elements: ToMany<PageElements, Element> = ToMany.empty(),
) : Referenceable

/** Owns Page containment of authored element resources. */
@TypewriterRelation(
    id = PAGE_ELEMENTS_RELATION_ID,
    onSourceDelete = RelationDeletePolicy.CASCADE,
    onTargetDelete = RelationDeletePolicy.CLEAR,
)
sealed interface PageElements : Relation<Page, Element>

const val BOOK_PAGES_RELATION_ID = "4fbbe0dcedd84ccb8b7ce8c6a6105551"
const val PAGE_ELEMENTS_RELATION_ID = "349b4d11c4464d13ad4ca063ead60c62"

/**
 * Provides the editor view of a page with logical element values and reference diagnostics.
 *
 * Element identities and source slot pairs must be unique. Cross page summaries may describe missing resources.
 * [compileStatus] reports publication state separately from whether the document can be edited.
 */
@Serializable
data class PageDocument(
    val page: Resource<PageId, Page>,
    val elements: List<PageDocumentElement>,
    val references: List<PageReference>,
    val incomingReferences: List<PageReference>,
    val crossPageTargets: List<ReferenceResourceResolution>,
    val crossPageSources: List<ReferenceResourceResolution>,
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
        val localTargets = elements.mapTo(hashSetOf(), PageDocumentElement::id) + page.id.value
        require(incomingReferences.all { it.target in localTargets }) {
            "Incoming page document references must target the page or one of its elements."
        }
        require(incomingReferences.map { it.source to it.slot }.distinct().size == incomingReferences.size) {
            "Incoming page document reference slots must be unique per source."
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
    val id: ResourceId,
    val elementType: ElementTypeId,
    val schemaRevision: Int,
    val value: DataValue,
    val placement: Placement,
)

/**
 * Connects an element slot to a resource and records the type expected by that slot.
 *
 * The target may be unresolved in an editable document. Resolution and diagnostic reporting belong to the
 * repository that assembled the document.
 */
@Serializable
data class PageReference(
    val source: ResourceId,
    val slot: ReferenceSlotId,
    val target: ResourceId,
    val expectedType: com.typewritermc.types.TypeExpression,
)

/**
 * Reports an authoring or reference problem without making the document unavailable to the editor.
 *
 * Optional locations let consumers focus the affected element, slot, or resource; a document level diagnostic
 * leaves them absent.
 */
@Serializable
data class PageDocumentDiagnostic(
    val code: String,
    val message: String,
    val element: ResourceId? = null,
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
