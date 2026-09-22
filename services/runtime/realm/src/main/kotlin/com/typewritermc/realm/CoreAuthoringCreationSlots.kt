package com.typewritermc.realm

import com.typewritermc.authoring.AuthoringCreationContext
import com.typewritermc.library.Book
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.library.Page
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.Tag
import com.typewritermc.pages.PageCatalog
import com.typewritermc.pages.ResolvedPageEditorDefinition
import com.typewritermc.types.DataPath
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry

private const val BOOK_CREATION_SLOT = "typewriter:book"
private const val TAG_CREATION_SLOT = "typewriter:tag"
private const val PAGE_CREATION_SLOT = "typewriter:page"

/** Builds the core creation slots from the same resolved page descriptors exposed to the editor. */
internal fun coreAuthoringCreationSlots(
    pageCatalog: PageCatalog,
    prototypes: TypePrototypeRegistry,
    types: TypeCatalog,
): List<AuthoringCreationSlotDefinition> {
    val definitions =
        listOf(
            AuthoringCreationSlotDefinition(
                id = AuthoringCreationSlotId(BOOK_CREATION_SLOT),
                label = "Book",
                creates = CoreResourceDefinitionIds.BOOK,
                context = AuthoringCreationContext.Standalone,
                concreteRoots = listOf(prototypes.require(Book::class).type),
            ),
            AuthoringCreationSlotDefinition(
                id = AuthoringCreationSlotId(TAG_CREATION_SLOT),
                label = "Tag",
                creates = CoreResourceDefinitionIds.TAG,
                context = AuthoringCreationContext.Standalone,
                concreteRoots = listOf(prototypes.require(Tag::class).type),
            ),
            AuthoringCreationSlotDefinition(
                id = AuthoringCreationSlotId(PAGE_CREATION_SLOT),
                label = "Page",
                creates = CoreResourceDefinitionIds.PAGE,
                context =
                    AuthoringCreationContext.ReferencePath(
                        hosts =
                            AuthoringCreationHostFilter(
                                definitions = setOf(CoreResourceDefinitionIds.BOOK),
                            ),
                        cardinality = AuthoringCreationHostCardinality.EXACTLY_ONE,
                        path = DataPath.field("book"),
                    ),
                concreteRoots = listOf(prototypes.require(Page::class).type),
            ),
        )
    val pageRoot = TypeExpression.Named(prototypes.require(Page::class).type)
    return definitions +
        pageCatalog.definitions.flatMap { page ->
            val editor = page.editor
            val (suffix, roots) =
                when (editor) {
                    is ResolvedPageEditorDefinition.Graph -> "graph" to editor.nodes
                    is ResolvedPageEditorDefinition.Timeline -> "timeline" to editor.tracks
                }
            listOf(
                AuthoringCreationSlotDefinition(
                    id = AuthoringCreationSlotId(pageSlotId(page.kind, suffix)),
                    label = "${page.name} ${if (suffix == "graph") "node" else "track"}",
                    creates = CoreResourceDefinitionIds.ELEMENT,
                    context =
                        AuthoringCreationContext.DeclaredRelation(
                            hosts =
                                AuthoringCreationHostFilter(
                                    definitions = setOf(CoreResourceDefinitionIds.PAGE),
                                    assignableTo = pageRoot,
                                ),
                            cardinality = AuthoringCreationHostCardinality.EXACTLY_ONE,
                            relation = RelationId(PAGE_ELEMENTS_RELATION_ID),
                            direction = AuthoringCreationRelationDirection.OUTGOING,
                        ),
                    concreteRoots = roots.flatMap { types.concreteSubtypesOf(it) }.distinct(),
                ),
            )
        }
}

private fun pageSlotId(
    kind: PageKindRef,
    suffix: String,
): String = "typewriter:page/${kind.id}/${kind.revision}/$suffix"

private fun TypeCatalog.concreteSubtypesOf(root: ResolvedTypeRef): List<ResolvedTypeRef> =
    buildList {
        definitions.singleOrNull { it.id == root }?.takeIf { it.kind == NominalTypeKind.CONCRETE }?.let { add(it.id) }
        addAll(subtypesOf(root).filter { it.kind == NominalTypeKind.CONCRETE }.map { it.id })
    }
