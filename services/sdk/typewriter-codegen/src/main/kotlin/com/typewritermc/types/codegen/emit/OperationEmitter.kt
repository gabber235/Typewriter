package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.parameterizedOrSelf
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * `XOperation<I>` for resources: an operation object on resource X with input `I` declares itself through
 * `XOperationSpec<I>`, whose drafts are drafts of the exact resource application. Generic resources keep their native
 * and draft type parameters before `I`.
 */
internal object OperationEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.resource) return
        val names = declaration.names
        val variables = declaration.operationVariables + declaration.operationInput
        val spec = names.operationSpec.parameterizedOrSelf(variables)
        val base = Api.OperationSpec.parameterizedBy(declaration.operationDraft, declaration.operationInput)
        addType(
            TypeSpec
                .interfaceBuilder(names.operation)
                .addKdoc(
                    "An operation on %T with input [%L], which is Unit or a `@TypewriterType`.",
                    names.source,
                    declaration.operationInput,
                ).addAnnotation(generatedContract(GeneratedContract.Kind.Operation, declaration))
                .addTypeVariables(variables)
                .addFunction(
                    FunSpec
                        .builder("declare")
                        .addModifiers(KModifier.ABSTRACT)
                        .receiver(spec)
                        .returns(Api.PreparedOperation)
                        .build(),
                ).build(),
        )
        addType(
            TypeSpec
                .interfaceBuilder(names.operationSpec)
                .addTypeVariables(variables)
                .addSuperinterface(base)
                .build(),
        )
        addType(
            TypeSpec
                .classBuilder(names.operationSpecImpl)
                .addTypeVariables(variables)
                .primaryConstructor(FunSpec.constructorBuilder().addParameter("spec", base).build())
                .addSuperinterface(base, "spec")
                // Last and not delegated, so a `where` clause cannot parse as an infix call on a delegate.
                .addSuperinterface(spec)
                .build(),
        )
    }
}

/** Operations of a generic resource are written against its exact drafts, which carry native and draft variables. */
internal val SdkDeclaration.operationVariables: List<TypeVariableName>
    get() = if (generic) exactVariables else emptyList()

/** The input type variable of operation contracts, named apart from the resource's own variables. */
internal val SdkDeclaration.operationInput: TypeVariableName
    get() {
        val taken = operationVariables.mapTo(hashSetOf()) { it.name }
        return TypeVariableName(generateSequence("I") { "${it}0" }.first { it !in taken })
    }

/** The draft every operation of this resource reads and edits. */
internal val SdkDeclaration.operationDraft: TypeName
    get() = if (generic) names.exactDraft.parameterizedBy(exactVariables) else names.draft
