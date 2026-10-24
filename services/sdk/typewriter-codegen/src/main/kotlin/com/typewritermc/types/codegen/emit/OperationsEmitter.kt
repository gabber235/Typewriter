package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.parameterizedOrSelf
import com.typewritermc.codegen.TypewriterApi as Api

/** `XOperations` for resources: authored operations receive drafts of the exact resource application. */
internal object OperationsEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.resource) return
        val names = declaration.names
        val variables = declaration.operationVariables
        val scope = names.operationsScope.parameterizedOrSelf(variables)
        val operations = Api.ResourceOperationsScope.parameterizedBy(declaration.operationDraft)
        addType(
            TypeSpec
                .interfaceBuilder(names.operations)
                .addAnnotation(generatedContract(GeneratedContract.Kind.Operations, declaration))
                .addTypeVariables(variables)
                .addFunction(
                    FunSpec
                        .builder("operations")
                        .addModifiers(KModifier.ABSTRACT)
                        .receiver(scope)
                        .build(),
                ).build(),
        )
        addType(
            TypeSpec
                .interfaceBuilder(names.operationsScope)
                .addTypeVariables(variables)
                .addSuperinterface(operations)
                .build(),
        )
        val build = Api.ResourceOperationsBuildScope.parameterizedBy(declaration.operationDraft)
        addType(
            TypeSpec
                .classBuilder(names.operationsScopeImpl)
                .addTypeVariables(variables)
                .primaryConstructor(FunSpec.constructorBuilder().addParameter("build", build).build())
                .addProperty(PropertySpec.builder("build", build, KModifier.PRIVATE).initializer("build").build())
                .addSuperinterface(operations, "build")
                .addSuperinterface(scope)
                .build(),
        )
    }
}

/** Operations of a generic resource are written against its exact drafts, which carry native and draft variables. */
internal val SdkDeclaration.operationVariables: List<TypeVariableName>
    get() = if (generic) exactVariables else emptyList()

/** The draft every operation of this resource reads and edits. */
internal val SdkDeclaration.operationDraft: TypeName
    get() = if (generic) names.exactDraft.parameterizedBy(exactVariables) else names.draft
