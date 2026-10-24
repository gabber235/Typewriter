package com.typewritermc.expression.operations

import com.typewritermc.types.actualType
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.with
import skirout.editor.v1.type_catalog.DataValue

/** Realm's kernel of the record operations. */
internal object PortableRecordKernel : RecordKernel {
    /** Replaces the field below any nominal wrappers and keeps those wrappers, so the result has the source's type. */
    override fun withField(
        source: DataValue,
        field: String,
        value: DataValue,
    ): DataValue =
        when (source) {
            is DataValue.NamedWrapper -> DataValue.named(source.actualType, withField(source.payload, field, value))
            is DataValue.RecordWrapper -> DataValue.RecordWrapper(source.value.with(field, value))
            else -> throw illTyped("Expected a record.")
        }
}
