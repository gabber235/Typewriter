package com.typewritermc.library

import com.typewritermc.authoring.bind
import com.typewritermc.authoring.orNull
import com.typewritermc.elements.ElementFields
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.Dynamics
import com.typewritermc.formula.ScopeBuilder
import com.typewritermc.formula.TypewriterDynamicProvider
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toSkir

/**
 * What library content can see: a page's elements see each other by name, and a book's pages see the elements of
 * every page of that book. A nearer level wins, so an element on the same page beats one on another page.
 */
@TypewriterDynamicProvider
object LibraryDynamic : DynamicProvider {
    override fun Dynamics.register() {
        each(PageDraftType) { page -> scopeContents { addNamedElements(page.id) } }
        each(BookDraftType) { book ->
            scopeContents { read(BookFields.pages.bind(book.id)).orNull().orEmpty().forEach { addNamedElements(it.target) } }
        }
    }

    /** Each named element of [page]. A broken field on one element only drops that element. */
    private fun ScopeBuilder.addNamedElements(page: ResourceId) {
        read(PageFields.elements.bind(page)).orNull().orEmpty().forEach { element ->
            read(ElementFields.name.bind(element.target)).orNull()?.takeIf { it.isNotBlank() }?.let { name ->
                resource(name, element.target.toSkir())
            }
        }
    }
}
