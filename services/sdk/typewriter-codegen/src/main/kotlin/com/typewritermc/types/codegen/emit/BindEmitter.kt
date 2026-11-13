package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.types.catalog.BindKey
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter

/** `XBind`: one key per `@Bind` parameter, named like the parameter, for the bind block that derives its type. */
internal object BindEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        val bound = declaration.definition.parameters.filter { it.derived }
        if (bound.isEmpty()) return
        addType(
            TypeSpec
                .objectBuilder(declaration.names.bind)
                .addProperties(
                    bound.map { parameter ->
                        PropertySpec
                            .builder(parameter.name, BindKey::class.asClassName())
                            .initializer("%T(%S)", BindKey::class.asClassName(), parameter.name)
                            .build()
                    },
                ).build(),
        )
    }
}
