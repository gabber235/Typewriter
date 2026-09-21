package com.typewritermc.realm.routes

import com.typewritermc.elements.ElementCatalog
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.library.ResourceIdentity
import com.typewritermc.library.ResourceTypeDescriptor
import com.typewritermc.library.Tag
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import skirout.editor.v1.typed_value.TypedValueEnvelope
import skirout.library.v1.authoring.PresentationSubject

/** Projects one hydrated resource through Realm owned catalog metadata. */
internal class AuthoringSubjectProjector(
    private val prototypes: TypePrototypeRegistry,
    private val elements: () -> ElementCatalog,
    private val pages: () -> PageCatalog,
) {
    fun <T : Any> encode(value: T): TypedValueEnvelope = prototypes.encode(value).toWire()

    fun project(
        resource: AuthoringGraphResource,
        edges: List<StoredResourceRelation>,
    ): PresentationSubject {
        val decoded = prototypes.decode(resource.content)
        val root = (resource.content.rootType as TypeExpression.Named).reference
        val descriptor =
            when (decoded) {
                is Book -> {
                    ResourceTypeDescriptor(
                        root,
                        "Book",
                        "Authored page collection",
                        Icon.Iconify("material-symbols:book"),
                        Color(0xff3f51b5u),
                    )
                }

                is Tag -> {
                    ResourceTypeDescriptor(
                        root,
                        "Tag",
                        "Library classification",
                        Icon.Iconify("material-symbols:label"),
                        Color(0xff795548u),
                    )
                }

                is Page -> {
                    val definition = pages().definition(decoded.kind)
                    ResourceTypeDescriptor(
                        root,
                        definition?.name ?: "Page",
                        definition?.description.orEmpty(),
                        definition?.icon ?: Icon.Iconify("material-symbols:description"),
                        definition?.color ?: Color(0xff607d8bu),
                    )
                }

                else -> {
                    val definition = elements().descriptor(root)
                    ResourceTypeDescriptor(
                        root,
                        definition?.name ?: "Element",
                        definition?.description.orEmpty(),
                        definition?.icon ?: Icon.Iconify("material-symbols:extension"),
                        definition?.color ?: Color(0xff607d8bu),
                    )
                }
            }
        val owner =
            edges
                .firstOrNull { edge ->
                    edge.target == resource.id && edge.origin is ResourceRelationOrigin.Declared
                }?.source
        return PresentationSubject(
            content = resource.content.toWire(),
            descriptor = prototypes.encode(descriptor).toWire(),
            identity = prototypes.encode(ResourceIdentity(resource.id, owner)).toWire(),
        )
    }
}
