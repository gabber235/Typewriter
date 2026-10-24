@file:OptIn(ExperimentalKotlinPoetApi::class)

package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.BOOLEAN
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.ExperimentalKotlinPoetApi
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LambdaTypeName
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterSpec
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.typewritermc.codegen.appliedUseCode
import com.typewritermc.types.ResourceId
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.SdkField
import com.typewritermc.types.codegen.containsParameter
import com.typewritermc.types.codegen.draftProjection
import com.typewritermc.types.codegen.draftType
import com.typewritermc.types.codegen.parameterizedOrSelf
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import com.typewritermc.codegen.TypewriterApi as Api

/** `XDraft`, its projection, the exact draft of generic declarations and the draft types of resources. */
internal object DraftEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        addType(declaration.draft())
        if (declaration.record) {
            if (declaration.generic) addFunction(declaration.draftProjectionFunction()) else addType(declaration.draftProjectionObject())
        }
        if (declaration.generic) addType(declaration.exactDraft())
        if (declaration.resource) {
            if (declaration.generic) {
                addType(declaration.genericDraftType())
                addType(declaration.exactDraftType())
            } else {
                addType(declaration.draftType())
            }
        }
    }

    private val SdkDeclaration.draftClass: TypeName get() = names.draft.parameterizedOrSelf(draftVariables)
    private val SdkDeclaration.exactDraftClass: TypeName get() = names.exactDraft.parameterizedOrSelf(exactVariables)

    private fun SdkDeclaration.projectionParameters(): List<ParameterSpec> =
        draftVariables.mapIndexed { index, variable -> ParameterSpec("argument$index", Api.ReadProjection.parameterizedBy(variable)) }

    private fun SdkDeclaration.projectionProperties(): List<PropertySpec> =
        projectionParameters().map { PropertySpec.builder(it.name, it.type, KModifier.PRIVATE).initializer(it.name).build() }

    private fun SdkDeclaration.projectionArguments(): CodeBlock =
        draftVariables.indices.map { CodeBlock.of("argument%L", it) }.joinToCode(",♢")

    private fun SdkDeclaration.draft(): TypeSpec {
        val binding = PropertySpec.builder("binding", Api.DraftBinding, KModifier.INTERNAL).initializer("binding").build()
        return TypeSpec
            .classBuilder(names.draft)
            .addModifiers(KModifier.OPEN)
            .addTypeVariables(draftVariables)
            .primaryConstructor(
                FunSpec
                    .constructorBuilder()
                    .addModifiers(KModifier.INTERNAL)
                    .addParameter("binding", Api.DraftBinding)
                    .addParameters(projectionParameters())
                    .build(),
            ).addProperty(binding)
            .addProperties(projectionProperties())
            .addSuperinterface(if (resource) Api.ResourceDraft else Api.DraftView)
            .addProperty(delegated("catalog", CatalogGeneration::class.asClassName(), "binding.catalog"))
            .addProperty(delegated("readContext", Api.ReadContext, "binding.readContext"))
            .addProperty(delegated("location", ValueLocation::class.asClassName(), "binding.location"))
            .addProperty(
                PropertySpec
                    .builder("actualType", Api.Availability.parameterizedBy(NamedTypeUse::class.asClassName()), KModifier.OVERRIDE)
                    .initializer(
                        CodeBlock
                            .builder()
                            .beginControlFlow("when (val selected = binding.actual)")
                            .addStatement("is %T·->♢%T(selected.value)", TypeSelection.CompleteWrapper::class, Api.AvailabilityAvailable)
                            .addStatement(
                                "is %T·->♢%T(listOf(binding.location))",
                                TypeSelection.PendingWrapper::class,
                                Api.AvailabilityUnavailable,
                            ).addStatement("else·->♢%M(selected)", UNKNOWN_VARIANT)
                            .endControlFlow()
                            .build(),
                    ).build(),
            ).apply {
                if (resource) {
                    addProperty(
                        delegated("id", ResourceId::class.asClassName(), CodeBlock.of("binding.location.resource.%M()", TO_RESOURCE_ID)),
                    )
                }
            }.addProperties(fields.map { draftField(it) })
            .addFunctions(fields.filterNot { it.template.containsParameter }.flatMap { editMethods(it) })
            .build()
    }

    private fun delegated(
        name: String,
        type: TypeName,
        value: String,
    ): PropertySpec = delegated(name, type, CodeBlock.of("%L", value))

    private fun delegated(
        name: String,
        type: TypeName,
        value: CodeBlock,
    ): PropertySpec =
        PropertySpec
            .builder(name, type, KModifier.OVERRIDE)
            .getter(FunSpec.getterBuilder().addStatement("return %L", value).build())
            .build()

    private fun SdkDeclaration.draftField(field: SdkField): PropertySpec =
        PropertySpec
            .builder(field.property, Api.Availability.parameterizedBy(field.shape.draftType(draftVariables)))
            .contextParameter("reads", Api.AuthoredReads)
            .getter(
                FunSpec
                    .getterBuilder()
                    .addStatement(
                        "return binding.%M(%L,♢%L)",
                        Api.read,
                        field.valuePath(),
                        context(draftBindings, references) { field.shape.draftProjection() },
                    ).build(),
            ).build()

    private fun SdkDeclaration.editMethods(field: SdkField): List<FunSpec> {
        val suffix = field.property.replaceFirstChar(Char::uppercaseChar)
        val path =
            CodeBlock.of(
                "binding.%M(%L,♢%L)",
                Api.exactEditablePath,
                field.valuePath(),
                context(draftBindings, references) { field.template.appliedUseCode() },
            )
        val set =
            FunSpec
                .builder("set$suffix")
                .addModifiers(KModifier.SUSPEND)
                .contextParameter("edits", Api.EditContext)
                .addParameter("value", field.shape.native)
                .addStatement("edits.set(%L,♢value)", path)
                .build()
        val clear =
            FunSpec
                .builder("clear$suffix")
                .addModifiers(KModifier.SUSPEND)
                .contextParameter("edits", Api.EditContext)
                .addStatement("edits.clear<%T>(%L)", field.shape.native, path)
                .build()
        return listOf(set, clear)
    }

    /** The read projection of a non generic record draft. */
    private fun SdkDeclaration.draftProjectionObject(): TypeSpec =
        TypeSpec
            .objectBuilder(names.draftProjection)
            .addSuperinterface(
                Api.ReadProjection.parameterizedBy(names.draft),
                CodeBlock.of("%M(%T.use,♢::%T)", Api.draftViewProjection, names.definition, names.draft),
            ).build()

    /** Generic record drafts project through a function that applies the projections of their type arguments. */
    private fun SdkDeclaration.draftProjectionFunction(): FunSpec {
        val uses = draftVariables.indices.map { CodeBlock.of("argument%L.expected", it) }.joinToCode(",♢")
        return FunSpec
            .builder(names.draftProjection.simpleName)
            .addTypeVariables(draftVariables)
            .addParameters(projectionParameters())
            .returns(Api.ReadProjection.parameterizedBy(draftClass))
            .addCode(
                "return %M(%T.applied(listOf(%L))) { binding·->♢%T(binding,♢%L) }\n",
                Api.draftViewProjection,
                names.definition,
                uses,
                names.draft,
                projectionArguments(),
            ).build()
    }

    private fun SdkDeclaration.exactDraft(): TypeSpec =
        TypeSpec
            .classBuilder(names.exactDraft)
            .addTypeVariables(exactVariables)
            .primaryConstructor(
                FunSpec
                    .constructorBuilder()
                    .addModifiers(KModifier.INTERNAL)
                    .addParameter("binding", Api.DraftBinding)
                    .addParameters(projectionParameters())
                    .build(),
            ).addProperties(projectionProperties())
            .superclass(draftClass)
            .addSuperclassConstructorParameter("binding")
            .apply { draftVariables.indices.forEach { addSuperclassConstructorParameter("argument%L", it) } }
            .addFunctions(fields.filter { it.template.containsParameter }.flatMap { editMethods(it) })
            .build()

    private fun SdkDeclaration.draftType(): TypeSpec =
        TypeSpec
            .objectBuilder(names.draftType)
            .addSuperinterface(Api.DraftType.parameterizedBy(names.draft))
            .addProperty(definitionMatch())
            .addFunction(bind(names.draft, CodeBlock.of("%T(binding)", names.draft)))
            .addFunction(where(names.draft, CodeBlock.of("%T", names.expressionsFactory)))
            .build()

    private fun SdkDeclaration.genericDraftType(): TypeSpec =
        TypeSpec
            .classBuilder(names.draftType)
            .addTypeVariables(draftVariables)
            .primaryConstructor(FunSpec.constructorBuilder().addParameters(projectionParameters()).build())
            .addProperties(projectionProperties())
            .addSuperinterface(Api.DraftType.parameterizedBy(draftClass))
            .addProperty(definitionMatch())
            .addFunction(bind(draftClass, CodeBlock.of("%T(binding,♢%L)", names.draft, projectionArguments())))
            .build()

    private fun SdkDeclaration.exactDraftType(): TypeSpec {
        val uses = draftVariables.indices.map { CodeBlock.of("argument%L.expected", it) }.joinToCode(",♢")
        return TypeSpec
            .classBuilder(names.exactDraftType)
            .addTypeVariables(exactVariables)
            .primaryConstructor(FunSpec.constructorBuilder().addParameters(projectionParameters()).build())
            .addProperties(projectionProperties())
            .addSuperinterface(Api.DraftType.parameterizedBy(exactDraftClass))
            .addProperty(
                PropertySpec
                    .builder("application", NamedTypeUse::class.asClassName(), KModifier.PRIVATE)
                    .initializer("%T.applied(listOf(%L))", names.definition, uses)
                    .build(),
            ).addProperty(
                PropertySpec
                    .builder("match", Api.ResourceTypeMatch, KModifier.OVERRIDE)
                    .initializer("%T(application)", Api.ResourceTypeMatchApplication)
                    .build(),
            ).addFunction(bind(exactDraftClass, CodeBlock.of("%T(binding,♢%L)", names.exactDraft, projectionArguments())))
            .addFunction(
                where(
                    exactDraftClass,
                    CodeBlock.of("%T as %T", names.expressionsFactory, Api.ExpressionFactory.parameterizedBy(expressionsType)),
                ),
            ).build()
    }

    private fun SdkDeclaration.definitionMatch(): PropertySpec =
        PropertySpec
            .builder("match", Api.ResourceTypeMatch, KModifier.OVERRIDE)
            .initializer("%T(%T.id)", Api.ResourceTypeMatchDefinition, names.definition)
            .build()

    private fun bind(
        draft: TypeName,
        construction: CodeBlock,
    ): FunSpec =
        FunSpec
            .builder("bind")
            .addModifiers(KModifier.OVERRIDE)
            .addParameter("binding", Api.DraftBinding)
            .returns(draft)
            .addStatement("return %L", construction)
            .build()

    private fun SdkDeclaration.where(
        draft: TypeName,
        factory: CodeBlock,
    ): FunSpec =
        FunSpec
            .builder("where")
            .addParameter(
                "predicate",
                LambdaTypeName.get(receiver = expressionsType, returnType = Api.Expr.parameterizedBy(BOOLEAN, OUT_MISSING)),
            ).returns(Api.TypedSelection.parameterizedBy(draft))
            .addStatement("return %M(this,♢%L,♢predicate)", Api.compileSelection, factory)
            .build()
}

private val UNKNOWN_VARIANT = MemberName("com.typewritermc.types", "unknownVariant")
private val TO_RESOURCE_ID = MemberName("com.typewritermc.types", "toResourceId", isExtension = true)
