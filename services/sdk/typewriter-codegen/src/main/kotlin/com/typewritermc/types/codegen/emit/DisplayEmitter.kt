package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.STRING
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.parameterizedOrSelf
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * `XDisplay` for resources: the name, accent and icon formulas of resource X. Every formula defaults to the subject's
 * type display, so an empty object is a complete declaration. `XDisplayScope` reads the subject's fields and type.
 */
internal object DisplayEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.resource) return
        val names = declaration.names
        val variables = declaration.typeVariables
        val scope = names.displayScope.parameterizedOrSelf(variables)
        addType(
            TypeSpec
                .interfaceBuilder(names.display)
                .addKdoc("How %T names and marks itself everywhere. Each formula defaults to the type display.", names.source)
                .addAnnotation(generatedContract(GeneratedContract.Kind.Display, declaration))
                .addTypeVariables(variables)
                .addFunction(formula(scope, "label", STRING, Api.defaultDisplayLabel))
                .addFunction(formula(scope, "accent", Color::class.asClassName(), Api.defaultDisplayAccent))
                .addFunction(formula(scope, "icon", Icon::class.asClassName(), Api.defaultDisplayIcon))
                .build(),
        )
        addType(
            TypeSpec
                .interfaceBuilder(names.displayScope)
                .addKdoc("The fields of %T plus its published type, which display formulas read.", names.source)
                .addTypeVariables(variables)
                .addSuperinterface(declaration.expressionsType)
                .addSuperinterface(Api.ResourceDisplayScope)
                .build(),
        )
        addType(
            TypeSpec
                .classBuilder(names.displayScopeImpl)
                .addTypeVariables(variables)
                .addSuperinterface(
                    declaration.expressionsType,
                    CodeBlock.of(
                        "%T(%T.value)",
                        names.expressionsImpl.parameterizedOrSelf(variables),
                        Api.ResourceDisplaySubject,
                    ),
                ).addSuperinterface(Api.ResourceDisplayScope, CodeBlock.of("%T", Api.ResourceDisplaySubject))
                // Last and not delegated, so a `where` clause cannot parse as an infix call on a delegate.
                .addSuperinterface(scope)
                .build(),
        )
    }

    /** `fun XDisplayScope.name(): Expr<T, Handled> = defaultName()`, the part of the subject's type display. */
    private fun formula(
        scope: TypeName,
        name: String,
        result: TypeName,
        default: MemberName,
    ): FunSpec =
        FunSpec
            .builder(name)
            .receiver(scope)
            .returns(Api.Expr.parameterizedBy(result, Api.Handled))
            .addStatement("return %M()", default)
            .build()
}
