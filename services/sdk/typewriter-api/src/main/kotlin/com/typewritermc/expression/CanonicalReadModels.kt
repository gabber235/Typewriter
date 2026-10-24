package com.typewritermc.expression

import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.catalog.ResourceAppearance
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse

/**
 * The framework read model roots. Every expression read schema derives from these Skir types and the types they
 * reach; the panel lists the same roots in `canonical_read_models.dart`.
 */
object CanonicalReadModels : CanonicalReadModelRegistry(
    listOf(TypeUse.serializer, TypeSelection.serializer, PublishedType.serializer, ResourceAppearance.serializer),
) {
    val typeUse: CanonicalReadModel<TypeUse> = model(TypeUse.serializer)
    val typeSelection: CanonicalReadModel<TypeSelection> = model(TypeSelection.serializer)
    val publishedType: CanonicalReadModel<PublishedType> = model(PublishedType.serializer)
    val resourceAppearance: CanonicalReadModel<ResourceAppearance> = model(ResourceAppearance.serializer)
}
