package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.TypeUse

interface DraftView {
    val catalog: CatalogGeneration
    val readContext: ReadContext
    val location: ValueLocation
    val actualType: Availability<TypeUse.Named>
}

interface DraftCodec<T> {
    val expected: TypeUse

    context(reads: AuthoredReads)
    fun read(binding: DraftBinding): Availability<T>
}
