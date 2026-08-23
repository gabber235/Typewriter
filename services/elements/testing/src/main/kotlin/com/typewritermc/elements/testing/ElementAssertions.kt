package com.typewritermc.elements.testing

import com.typewritermc.elements.ElementCatalog
import com.typewritermc.elements.ElementTypeId

fun ElementCatalog.requireElement(id: ElementTypeId) =
    entries.singleOrNull { it.descriptor.id == id }
        ?: error("Expected element catalog to contain $id.")
