@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.testing

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.catalog.CheckedType
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.TypeDefinitionId

/**
 * A concrete native binding for every record of [type] that reads none of its fields, so hand written types of a
 * [DefinitionCatalog] can be constructed the way publication requires. [construct] builds the native value; a
 * [construct] that throws makes native construction fail.
 */
fun recordBinding(
    type: TypeDefinitionId,
    construct: () -> Any = {},
): NativeBindingFactory =
    object : NativeBindingFactory {
        override val definition = type
        override val provider = NativeBindingId(value = "fixture.record")

        override fun bind(
            actual: CheckedType,
            arguments: AppliedNativeArguments,
        ): NativeBinding<*> = GeneratedRecordNativeBinding(actual, provider, "fixture.record", Any::class, emptyList()) { construct() }
    }
