package com.typewritermc.realm.catalog

import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.ContentSource
import com.typewritermc.types.catalog.contentSourceOf
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.kernel.v1.resource_id.ResourceId

/**
 * A view's catalog: the code catalog plus what that view's resources declare. Every reader of a view's catalog gets
 * content types with no edit of its own, and none can pick the code catalog by mistake. Retention stays with [code].
 */
internal class ViewCatalogLease(
    val code: AuthoringCatalogLease,
    source: ContentSource,
) : AuthoringCatalogLease by code {
    override val checked: CheckedCatalog = code.checked.withContent(source)

    /** A view is immutable, so bindings per view never hold an old schema. */
    override val nativeBindings: NativeBindingRegistry by lazy { code.nativeBindings.over(checked) }

    override fun retain(): AuthoringCatalogLease = code.retain()
}

/** The code catalog of this lease, without any view's content. */
internal val AuthoringCatalogLease.code: AuthoringCatalogLease get() = (this as? ViewCatalogLease)?.code ?: this

/** The code catalog plus what [resources] declare. */
internal fun AuthoringCatalogLease.over(resources: Map<ResourceId, AuthoringRecord>): ViewCatalogLease =
    ViewCatalogLease(code, contentSourceOf(resources::get))
