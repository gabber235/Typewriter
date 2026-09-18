package com.typewritermc.types

/** Physical authoring family derived from nominal reference ancestry. */
enum class ReferenceFamily(
    val table: String,
) {
    BOOK("book"),
    PAGE("page"),
    TAG("tag"),
    ELEMENT("element"),
}

/** Resolves one reference target to exactly one authoring resource family. */
fun TypeCatalog.referenceFamily(target: ResolvedTypeRef): ReferenceFamily {
    val definitionsById = definitions.associateBy { it.id.withoutArguments() }
    val closure = linkedSetOf(target.withoutArguments())
    val pending = ArrayDeque<ResolvedTypeRef>().apply { add(target.withoutArguments()) }
    while (pending.isNotEmpty()) {
        definitionsById[pending.removeFirst()]
            ?.parents
            .orEmpty()
            .map(ResolvedTypeRef::withoutArguments)
            .filter(closure::add)
            .forEach(pending::add)
    }
    require(REFERENCEABLE_TYPE in closure) {
        "Reference target $target does not inherit Referenceable."
    }
    val families =
        buildSet {
            if (BOOK_TYPE in closure) add(ReferenceFamily.BOOK)
            if (PAGE_TYPE in closure || PAGE_KIND_TYPE in closure) add(ReferenceFamily.PAGE)
            if (TAG_TYPE in closure) add(ReferenceFamily.TAG)
            if (ELEMENT_TYPE in closure) add(ReferenceFamily.ELEMENT)
        }
    require(families.size == 1) {
        "Reference target $target must resolve to exactly one resource family, found ${families.size}."
    }
    return families.single()
}

/** Reports whether a concrete candidate nominal type satisfies the declared reference target. */
fun TypeCatalog.acceptsReferenceCandidate(
    target: ResolvedTypeRef,
    candidateTypes: Collection<ResolvedTypeRef>,
): Boolean {
    val targetBase = target.withoutArguments()
    return candidateTypes.any { candidate ->
        val candidateBase = candidate.withoutArguments()
        candidateBase == targetBase || subtypesOf(target).any { it.id.withoutArguments() == candidateBase }
    }
}

private fun ResolvedTypeRef.withoutArguments(): ResolvedTypeRef = copy(arguments = emptyList())

private val REFERENCEABLE_TYPE = qualified("com.typewritermc.types", "Referenceable")
private val BOOK_TYPE = qualified("com.typewritermc.library", "Book")
private val PAGE_TYPE = qualified("com.typewritermc.library", "Page")
private val PAGE_KIND_TYPE = qualified("com.typewritermc.library", "PageKind")
private val TAG_TYPE = qualified("com.typewritermc.library", "Tag")
private val ELEMENT_TYPE = qualified("com.typewritermc.elements", "Element")

private fun qualified(
    namespace: String,
    name: String,
): ResolvedTypeRef = ResolvedTypeRef(TypeId.Qualified(namespace, name), revision = 1)
