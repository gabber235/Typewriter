package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.types.catalog.BindKey
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter

/**
 * `XBind`: one key per type parameter of a concrete resource class, named like the parameter. A bind registered for a
 * key makes that parameter computed; a parameter without one stays creator chosen.
 */
internal object BindEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.resource || declaration.abstract || !declaration.generic) return
        addType(
            TypeSpec
                .objectBuilder(declaration.names.bind)
                .addProperties(
                    declaration.definition.parameters.map { parameter ->
                        PropertySpec
                            .builder(parameter.name, BindKey::class.asClassName())
                            .initializer("%T(%T.id,♢%S)", BindKey::class.asClassName(), declaration.names.definition, parameter.name)
                            .build()
                    },
                ).build(),
        )
    }
}
