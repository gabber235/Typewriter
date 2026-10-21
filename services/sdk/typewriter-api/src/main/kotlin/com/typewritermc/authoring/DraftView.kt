package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeUse

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
