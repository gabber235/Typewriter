package com.typewritermc.elements

import com.typewritermc.discovery.RuntimeScope

interface EntryOutput {
    suspend fun send(value: Any)
}

interface EntryExecutionContext : RuntimeScope {
    val output: EntryOutput
}

interface ElementRuntimeContext : RuntimeScope

interface ExecutableEntry : Entry {
    context(context: EntryExecutionContext)
    suspend fun execute()
}

interface ElementRuntimeHandle : AutoCloseable

interface ElementRuntimeFacet<E : Element> {
    context(context: ElementRuntimeContext)
    suspend fun attach(element: E): ElementRuntimeHandle
}
