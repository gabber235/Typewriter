package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.types.catalog.DerivedKey
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter

/** `XDerived`: one key per derived parameter, named like the parameter, for the derive block that computes its type. */
internal object DerivedEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        val derived = declaration.definition.parameters.filter { it.derived }
        if (derived.isEmpty()) return
        addType(
            TypeSpec
                .objectBuilder(declaration.names.derived)
                .addProperties(
                    derived.map { parameter ->
                        PropertySpec
                            .builder(parameter.name, DerivedKey::class.asClassName())
                            .initializer("%T(%S)", DerivedKey::class.asClassName(), parameter.name)
                            .build()
                    },
                ).build(),
        )
    }
}
