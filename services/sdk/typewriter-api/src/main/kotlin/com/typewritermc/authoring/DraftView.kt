package com.typewritermc.authoring

import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation

interface DraftView {
    val catalog: CatalogGeneration
    val readContext: ReadContext
    val location: ValueLocation
    val actualType: Availability<NamedTypeUse>
}

interface DraftCodec<T> {
    val expected: TypeUse

    context(reads: AuthoredReads)
    fun read(binding: DraftBinding): Availability<T>
}
