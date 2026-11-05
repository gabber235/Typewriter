package com.typewritermc.testkit

import com.typewritermc.authoring.of
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.payload
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse

/**
 * Encodes native Kotlin values the way the Realm does: [checked] resolves the type and [bindings] binds it, as Realm
 * provisioning encodes the records it creates.
 */
class CatalogEncoder(
    private val checked: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
) {
    /** The authored value [value] encodes to as [type]. */
    fun encode(
        type: TypeUse,
        value: Any?,
    ): DataValue {
        @Suppress("UNCHECKED_CAST")
        val binding = bindings.bind(checked.ready(type)) as NativeBinding<Any?>
        return binding.encode(value)
    }

    /** The saved record of a resource whose native value is [value] and whose type is [type]. */
    fun record(
        type: TypeUse,
        value: Any,
    ): AuthoringRecord {
        val encoded = encode(type, value) as DataValue.NamedWrapper
        val payload = encoded.payload as DataValue.RecordWrapper
        return AuthoringRecord.of(TypeSelection.CompleteWrapper(encoded.actualType), payload.value)
    }
}
