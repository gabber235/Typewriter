package com.typewritermc.library

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementRevision
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

@Serializable
data class Book(
    val id: BookId,
    val revision: ResourceRevision,
    val title: LibraryName,
    val icon: Icon,
    val color: Color,
    val tags: Set<Ref<Tag>>,
) : Referenceable

@Serializable
data class Tag(
    val id: TagId,
    val revision: ResourceRevision,
    val name: LibraryName,
    val color: Color,
    val parents: Set<Ref<Tag>>,
    val placement: GridPlacement,
) : Referenceable

@Serializable
data class Page(
    val id: PageId,
    val revision: ResourceRevision,
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

@JvmInline
@Serializable
value class PageDocumentRevision(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Page document revisions must not be blank." }
    }
}

@Serializable
data class PageDocument(
    val revision: PageDocumentRevision,
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

@Serializable
data class PageDocumentElement(
    val id: ElementInstanceId,
    val revision: ElementRevision,
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
