package com.typewritermc.testkit

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.discovery.CatalogAssembly
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse

/** The checked type [use] resolves to; fails with the catalog's diagnostics when it does not resolve. */
fun CheckedCatalog.ready(use: TypeUse): CheckedType = resolve(use).ready()

/** The complete value of this result; fails when the value is not complete. */
fun CompletenessResult.complete() = (this as CompletenessResult.Complete).value

/** The native binding of [use] in this assembly, as a binding of [T]; fails when [use] does not resolve. */
@Suppress("UNCHECKED_CAST")
fun <T> CatalogAssembly.binding(use: TypeUse): NativeBinding<T> = bindings.bind(checked.ready(use)) as NativeBinding<T>

/** [value] admitted as a complete value of [use] in this assembly; fails when it does not resolve or is incomplete. */
fun CatalogAssembly.admitted(
    use: TypeUse,
    value: DataValue,
) = checked.ready(use).complete(value).complete()
