package com.typewritermc.realm.repository.search

import com.surrealdb.Surreal
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.types.ReferenceFamily
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeId
import com.typewritermc.types.acceptsReferenceCandidate
import com.typewritermc.types.referenceFamily

internal fun Surreal.resolveAuthoringReferences(
    request: AuthoringReferenceResolutionRequest,
    elements: Map<ElementTypeId, ElementSearchCatalogEntry>,
    types: TypeCatalog,
): List<AuthoringReferenceSummary> {
    val family = types.referenceFamily(request.target)
    return request.ids.map { id ->
        if (id.table != family.table) return@map missing(id)
        resolveReference(id, family, elements)
            ?.takeIf { types.acceptsReferenceCandidate(request.target, it.compatibleTypes) }
            ?: missing(id)
    }
}

private fun Surreal.resolveReference(
    id: ResourceId,
    family: ReferenceFamily,
    elements: Map<ElementTypeId, ElementSearchCatalogEntry>,
): AuthoringReferenceSummary? =
    when (family) {
        ReferenceFamily.BOOK -> {
            val value =
                query(
                    "SELECT title FROM ONLY \$id;",
                    mapOf("id" to id.surrealId()),
                ).take(0)
            if (value.isNone || value.isNull) {
                null
            } else {
                AuthoringReferenceSummary(id, value.getObject().get("title").getString(), null, listOf(BOOK_TYPE), true)
            }
        }

        ReferenceFamily.TAG -> {
            val value = query("SELECT name FROM ONLY \$id;", mapOf("id" to id.surrealId())).take(0)
            if (value.isNone || value.isNull) {
                null
            } else {
                AuthoringReferenceSummary(id, value.getObject().get("name").getString(), null, listOf(TAG_TYPE), true)
            }
        }

        ReferenceFamily.PAGE -> {
            val value =
                query(
                    "SELECT name, book.title AS book_title, kind FROM ONLY \$id;",
                    mapOf("id" to id.surrealId()),
                ).take(0)
            if (value.isNone || value.isNull) {
                null
            } else {
                val row = value.getObject()
                val kind = row.get("kind").getObject()
                val kindType =
                    ResolvedTypeRef(
                        TypeId.Declared(
                            com.typewritermc.types.DeclaredTypeId
                                .parse(kind.get("id").getString()),
                        ),
                        kind.get("revision").getLong().toInt(),
                    )
                AuthoringReferenceSummary(
                    id,
                    row.get("name").getString(),
                    row.get("book_title").getString(),
                    listOf(PAGE_TYPE, kindType),
                    true,
                )
            }
        }

        ReferenceFamily.ELEMENT -> {
            val value =
                query(
                    "SELECT value.data.fields.name.value AS name, element_type, page.name AS page_name " +
                        "FROM ONLY \$id;",
                    mapOf("id" to id.surrealId()),
                ).take(0)
            if (value.isNone || value.isNull) {
                null
            } else {
                val row = value.getObject()
                val type =
                    ElementTypeId(
                        com.typewritermc.types.DeclaredTypeId
                            .parse(row.get("element_type").getString()),
                    )
                AuthoringReferenceSummary(
                    id,
                    row.get("name").getString(),
                    row.get("page_name").getString(),
                    elements[type]?.rootType()?.let(::listOf).orEmpty(),
                    true,
                )
            }
        }
    }

private fun missing(id: ResourceId) = AuthoringReferenceSummary(id, null, null, emptyList(), false)

private val BOOK_TYPE = qualified("com.typewritermc.library", "Book")
private val PAGE_TYPE = qualified("com.typewritermc.library", "Page")
private val TAG_TYPE = qualified("com.typewritermc.library", "Tag")

private fun qualified(
    namespace: String,
    name: String,
): ResolvedTypeRef = ResolvedTypeRef(TypeId.Qualified(namespace, name), revision = 1)
