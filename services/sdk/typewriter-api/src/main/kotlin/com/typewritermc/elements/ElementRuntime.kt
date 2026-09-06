package com.typewritermc.elements

import com.typewritermc.discovery.RuntimeScope

/**
 * Receives values emitted by executing entries.
 *
 * The runtime supplies routing and interpretation. Sending may suspend or fail, and this interface makes no
 * delivery, persistence, or ordering guarantee across concurrent senders.
 */
interface EntryOutput {
    suspend fun send(value: Any)
}

/**
 * Supplies activation resources and an output sink while an entry executes.
 *
 * Use inherited scope ownership for work that must end with the activation; [output] belongs to the runtime and is
 * not owned by the entry.
 */
interface EntryExecutionContext : RuntimeScope {
    val output: EntryOutput
}

/**
 * Supplies deployment codecs, facts, and resource ownership while a facet attaches to an element.
 */
interface ElementRuntimeContext : RuntimeScope

/**
 * Adds a suspending execution action to an authored entry.
 *
 * The invoking runtime supplies [EntryExecutionContext]. Implementations should propagate cancellation and
 * register acquired activation resources with the scope.
 */
interface ExecutableEntry : Entry {
    context(context: EntryExecutionContext)
    suspend fun execute()
}

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
    suspend fun attach(element: E): ElementRuntimeHandle
}
