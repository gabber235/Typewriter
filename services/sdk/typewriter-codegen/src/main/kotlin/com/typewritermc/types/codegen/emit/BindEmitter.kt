package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.NOTHING
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.typewritermc.codegen.TypewriterApi as Api
import com.typewritermc.types.catalog.BindKey
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import skirout.editor.v1.type_catalog.ParameterKey

/**
 * `XBind`: one handle per type parameter of a concrete resource class, named like the parameter. A bind registered for
 * a handle makes that parameter computed; a parameter without one stays creator chosen. Each handle carries a draft of
 * the resource that reads every parameter as unbound, since a bind computes from concrete content alone.
 */
internal object BindEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.resource || declaration.abstract || !declaration.generic) return
        val names = declaration.names
        val parameters = declaration.definition.parameters
        val draft = names.draft.parameterizedBy(parameters.map { NOTHING })
        val unbound =
            parameters.indices
                .map { index ->
                    CodeBlock.of(
                        "%M(%T(owner = %T.id, index = %L))",
                        Api.unboundReadProjection,
                        ParameterKey::class.asClassName(),
                        names.definition,
                        index,
                    )
                }.joinToCode(",♢")
        addType(
            TypeSpec
                .objectBuilder(names.bind)
                .addProperties(
                    parameters.map { parameter ->
                        PropertySpec
                            .builder(parameter.name, Api.BindParameter.parameterizedBy(draft))
                            .initializer(
                                "%T(%T(%T.id,♢%S),♢%T(%L))",
                                Api.BindParameter,
                                BindKey::class.asClassName(),
                                names.definition,
                                parameter.name,
                                names.draftType,
                                unbound,
                            ).build()
                    },
                ).build(),
        )
    }
}
