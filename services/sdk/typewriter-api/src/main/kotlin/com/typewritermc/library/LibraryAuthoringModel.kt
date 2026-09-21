package com.typewritermc.library

import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.Ref
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.Serializable

/** Typed presentation inputs shared by search, reference resolution, and document navigation. */
data class PresentationSubject(
    val content: TypedValueEnvelope,
    val descriptor: TypedValueEnvelope,
    val identity: TypedValueEnvelope,
)

/** Result of resolving one stable resource identity for presentation. */
sealed interface ReferenceResourceResolution {
    data class Resolved(
        val subject: PresentationSubject,
        val compatibleTypes: List<ResolvedTypeRef>,
    ) : ReferenceResourceResolution

    data class Missing(
        val id: ResourceId,
    ) : ReferenceResourceResolution

    data class Unavailable(
        val id: ResourceId,
        val diagnostics: List<ReferenceResourceDiagnostic>,
    ) : ReferenceResourceResolution
}

/** Explains why an existing resource cannot currently produce a typed presentation subject. */
data class ReferenceResourceDiagnostic(
    val code: String,
    val message: String,
)

/** Stable identity input supplied separately from editable presentation content. */
@TypewriterType(id = "214fdb63564640e5bc15c7524f6121ef")
data class ResourceIdentity(
    val id: ResourceId,
    val owner: ResourceId? = null,
)

/**
 * Describes one authored resource family for role presentations.
 *
 * Instance visuals remain canonical content. These values describe the family and authoring policy only.
 */
@TypewriterType(id = "da03c1ce637d4ee78c4916d304e57bf1")
data class ResourceTypeDescriptor(
    val type: ResolvedTypeRef,
    val name: String,
    val description: String,
    val icon: Icon,
    val color: Color,
)

/** Closed resource kind used by authoring search context and activation policy. */
@Serializable
enum class AuthoringResultKind {
    BOOK,
    TAG,
    PAGE,
    ELEMENT,
}

/** Locates the matched text inside the context field used for ranking and highlighting. */
@Serializable
data class AuthoringSearchMatch(
    val text: String,
    val start: Int,
    val end: Int,
) {
    init {
        require(start in 0..end && end <= text.length) { "Search match bounds must fit the matched text." }
    }
}

/**
 * Carries search specific navigation and match facts beside a resource presentation subject.
 *
 * Presentation content stays independent, allowing search and reference resolution to share the same projector.
 */
@TypewriterType(id = "6e959f2dc65342dc9a2409cf3497e09f")
data class AuthoringSearchContext(
    val kind: AuthoringResultKind,
    val book: Ref<Book>?,
    val page: Ref<Page>?,
    val chapter: ChapterPath?,
    val match: AuthoringSearchMatch?,
)

/** Canonical Realm projection consumed by tag lookup, search, and inheritance graph presentations. */
@TypewriterType(id = "9e9eaf947ed848a69fd1bbfc66cb13eb")
data class TagCollectionRow(
    val key: Ref<Tag>,
    val name: String,
    val color: Color,
    val parents: List<Ref<Tag>>,
    val selectable: Boolean,
)

const val TAG_COLLECTION_SOURCE_ID = "realm.tags"
const val TAG_INHERITS_RELATION_ID = "inherits"
