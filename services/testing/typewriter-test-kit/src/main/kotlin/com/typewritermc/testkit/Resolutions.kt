package com.typewritermc.testkit

import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import skirout.editor.v1.type_catalog.TypeUse

/** The checked type [use] resolves to; fails with the catalog's diagnostics when it does not resolve. */
fun CheckedCatalog.ready(use: TypeUse): CheckedType = resolve(use).ready()
