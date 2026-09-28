package com.typewritermc.elements

import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId

/**
 * Supplies deployment codecs, facts, and resource ownership while a facet attaches to an element.
 */
interface ElementRuntimeContext : RuntimeScope

/**
 * Owns the resources created by one facet attachment.
 *
 * The runtime must close the handle when that attachment is retired. Implementations define their own repeat
 * closure and thread requirements.
 */
interface ElementRuntimeHandle : AutoCloseable

/**
 * Attaches runtime behavior to an element without putting resource ownership into its serialized model.
 *
 * A successful attachment returns a handle that the caller must close. If attachment fails before returning a
 * handle, the facet must release resources it acquired or register them with the contextual scope.
 */
interface ElementRuntimeFacet<E : Element> {
    context(context: ElementRuntimeContext)
    suspend fun attach(element: Resource<ResourceId, E>): ElementRuntimeHandle
}
