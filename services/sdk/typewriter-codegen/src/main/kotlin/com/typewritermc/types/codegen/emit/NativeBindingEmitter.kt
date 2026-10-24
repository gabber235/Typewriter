package com.typewritermc.types.codegen.emit

import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.squareup.kotlinpoet.ANY
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.STRING
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.TypeParameterBindings
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.appliedUseCode
import com.typewritermc.codegen.compiledBounds
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.listCode
import com.typewritermc.codegen.serialName
import com.typewritermc.codegen.setCode
import com.typewritermc.codegen.valueClassScalarKind
import com.typewritermc.types.TypewriterString
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.erasedTypeName
import com.typewritermc.types.codegen.parameterizedOrSelf
import com.typewritermc.types.ksp.OwnedFieldDeclaration
import com.typewritermc.types.parameterKeys
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/** `XNativeBindingFactory`: converts between portable values and instances of a concrete declaration. */
internal object NativeBindingEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        if (!declaration.source.supportsNativeBinding()) return
        context(declaration.references) { addType(declaration.factory()) }
    }

    context(_: DefinitionReferences)
    private fun SdkDeclaration.factory(): TypeSpec {
        val signature = names.source.canonicalName
        val constructionPlan = constructionPlan()
        return TypeSpec
            .objectBuilder(names.nativeBindingFactory)
            .addSuperinterface(Api.NativeBindingFactory)
            .addProperty(
                PropertySpec
                    .builder("definition", TypeDefinitionId::class, KModifier.OVERRIDE)
                    .initializer("%T.id", names.definition)
                    .build(),
            ).addProperty(
                PropertySpec
                    .builder("provider", NativeBindingId::class, KModifier.OVERRIDE)
                    .initializer("%T(value = %S)", NativeBindingId::class, signature)
                    .build(),
            ).addProperty(
                PropertySpec
                    .builder("nativeClass", KClass::class.asClassName().parameterizedBy(STAR), KModifier.OVERRIDE)
                    .initializer("%T::class", names.source)
                    .build(),
            ).apply {
                constructionPlan?.let {
                    addProperty(
                        PropertySpec.builder("constructionPlan", Api.NativeConstructionPlan, KModifier.OVERRIDE).initializer(it).build(),
                    )
                }
            }.addFunction(
                FunSpec
                    .builder("bind")
                    .addModifiers(KModifier.OVERRIDE)
                    .addParameter("actual", CheckedType::class)
                    .addParameter("arguments", Api.AppliedNativeArguments)
                    .returns(Api.NativeBinding.parameterizedBy(STAR))
                    .addStatement("arguments.%M(%L)", Api.requireOpaqueCompatibility, opaqueArguments())
                    .addStatement("return %L", binding(signature))
                    .build(),
            ).build()
    }

    /** The declaration applied to the erasure of each type parameter. */
    private val SdkDeclaration.nativeApplied: TypeName
        get() =
            names.source.parameterizedOrSelf(
                source.typeParameters.map { parameter ->
                    parameter
                        .compiledBounds()
                        .firstOrNull()
                        ?.erasedTypeName()
                        ?: ANY.copy(nullable = true)
                },
            )

    /** Type parameter indexes without a compiled bound, which may be bound to opaque arguments. */
    private fun SdkDeclaration.opaqueArguments(): CodeBlock =
        source.typeParameters
            .mapIndexedNotNull { index, parameter ->
                index.takeUnless { parameter.compiledBounds().any() }
            }.map { CodeBlock.of("%L", it) }
            .setCode()

    context(_: DefinitionReferences)
    private fun SdkDeclaration.binding(signature: String): CodeBlock {
        val common =
            CodeBlock.of(
                "checked = actual,\nprovider = provider,\nsignature = %S,\nnativeClass = %T::class,\n",
                signature,
                names.source,
            )
        val declaration = source
        return when {
            declaration.annotation<TypewriterString>() != null -> {
                val property =
                    declaration.primaryConstructor
                        ?.parameters
                        ?.firstOrNull()
                        ?.name
                        ?.asString() ?: ownedFields.first().name
                scalarBinding(common, ScalarKind.TEXT, property, STRING)
            }

            declaration.classKind == ClassKind.ENUM_CLASS -> {
                val cases =
                    declaration.declarations
                        .filterIsInstance<KSClassDeclaration>()
                        .filter { it.classKind == ClassKind.ENUM_ENTRY }
                        .toList()
                val key = CodeBlock.builder().beginControlFlow("when (value)")
                cases.forEach { case -> key.add("%T.%N·->♢%S\n", names.source, case.simpleName.asString(), case.serialKey) }
                key.endControlFlow()
                val construct = CodeBlock.builder().beginControlFlow("when (key)")
                cases.forEach { case -> construct.add("%S·->♢%T.%N\n", case.serialKey, names.source, case.simpleName.asString()) }
                construct.add(
                    "else·->♢throw %T(%S,♢%P)\n",
                    Api.NativeBindingException,
                    "unknown_enum_case",
                    "Unknown enum case \$key.",
                )
                construct.endControlFlow()
                CodeBlock.of(
                    "%T(\n⇥%Lkey = { value ->\n⇥%L⇤},\nconstruct = { key ->\n⇥%L⇤},\n⇤)",
                    Api.GeneratedEnumNativeBinding.parameterizedBy(names.source),
                    common,
                    key.build(),
                    construct.build(),
                )
            }

            declaration.classKind == ClassKind.OBJECT -> {
                CodeBlock.of(
                    "%T(\n⇥%Lfields = emptyList(),\nconstruct = { %T },\n⇤)",
                    Api.GeneratedRecordNativeBinding.parameterizedBy(names.source),
                    common,
                    names.source,
                )
            }

            declaration.valueClassScalarKind() != null -> {
                val parameter = requireNotNull(declaration.primaryConstructor?.parameters?.singleOrNull())
                scalarBinding(
                    common,
                    requireNotNull(declaration.valueClassScalarKind()),
                    requireNotNull(parameter.name).asString(),
                    parameter.type.resolve().erasedTypeName(),
                )
            }

            else -> {
                recordBinding(common)
            }
        }
    }

    private fun SdkDeclaration.scalarBinding(
        common: CodeBlock,
        kind: ScalarKind,
        property: String,
        representation: TypeName,
    ): CodeBlock =
        CodeBlock.of(
            "%T(\n⇥%Lrepresentation = arguments.resolver.bind(%T(%L)),\nunwrap = { value·->♢value.%N },\nconstruct = { value·->♢%T(value as %T) },\n⇤)",
            Api.GeneratedScalarNativeBinding.parameterizedBy(nativeApplied),
            common,
            TypeUse.ScalarWrapper::class,
            kind.kotlinCode(),
            property,
            names.source,
            representation,
        )

    context(_: DefinitionReferences)
    private fun SdkDeclaration.recordBinding(common: CodeBlock): CodeBlock {
        val properties = ownProperties()
        val fields = ownedFields.mapNotNull { field -> properties[field.sourceName]?.let { field to it } }
        val bindings =
            fields
                .map { (field, _) ->
                    CodeBlock.of(
                        "%T(%S,♢{ arguments.resolver.bind(%L) },♢{ value·->♢value.%N })",
                        Api.GeneratedNativeField,
                        field.name,
                        field.template.nativeAppliedCode(definition.id),
                        field.sourceName,
                    )
                }.listCode()
        val constructor =
            fields
                .map { (field, property) ->
                    CodeBlock.of("%N = values.getValue(%S) as %T", field.sourceName, field.name, property.type.resolve().erasedTypeName())
                }.joinToCode(",\n")
        return CodeBlock.of(
            "%T(\n⇥%Lfields = %L,\nconstruct = { values ->\n⇥%T(\n⇥%L,\n⇤)\n⇤},\n⇤)",
            Api.GeneratedRecordNativeBinding.parameterizedBy(nativeApplied),
            common,
            bindings,
            names.source,
            constructor,
        )
    }

    /** Constructor defaults of concrete classes, which the authoring runtime samples to prefill new values. */
    context(_: DefinitionReferences)
    private fun SdkDeclaration.constructionPlan(): CodeBlock? {
        if (source.classKind != ClassKind.CLASS || source.annotation<TypewriterString>() != null) return null
        if (ownedFields.none(OwnedFieldDeclaration::hasConstructorDefault)) return null
        val ordered =
            source.primaryConstructor?.parameters.orEmpty().mapNotNull { parameter ->
                ownedFields.singleOrNull { it.sourceName == parameter.name?.asString() }
            }
        val descriptors =
            ordered.map { field ->
                CodeBlock.of(
                    "%T%L",
                    Api.GeneratedConstructorField.parameterizedBy(nativeApplied),
                    com.typewritermc.codegen.namedArguments(
                        "owner" to CodeBlock.of("%T(definition·=·%L,♢name·=·%S)", FieldOwner::class, field.owner.kotlinCode(), field.name),
                        "sourceName" to CodeBlock.of("%S", field.sourceName),
                        "hasDefault" to CodeBlock.of("%L", field.hasConstructorDefault),
                        "type" to CodeBlock.of("{ arguments·->♢%L }", field.template.nativeAppliedCode(definition.id)),
                        "read" to CodeBlock.of("{ value·->♢value.%N }", field.sourceName),
                    ),
                )
            }
        return CodeBlock.of(
            "(%T::class as %T).%M(\n⇥fields = %L,\nallowedOpaqueArguments = %L,\n⇤)",
            names.source,
            KClass::class.asClassName().parameterizedBy(nativeApplied),
            Api.constructorDefaults,
            descriptors.listCode(),
            opaqueArguments(),
        )
    }

    private fun SdkDeclaration.ownProperties(): Map<String, KSPropertyDeclaration> =
        source.declarations
            .filterIsInstance<KSPropertyDeclaration>()
            .associateBy { it.simpleName.asString() }
}

/** The applied type use of a template whose parameters read the native binding's portable arguments. */
context(_: DefinitionReferences)
private fun TypeTemplate.nativeAppliedCode(owner: TypeDefinitionId): CodeBlock {
    val bindings =
        TypeParameterBindings.from(
            parameterKeys().associateWith { key ->
                require(key.owner == owner)
                CodeBlock.of("arguments.portable[%L]", key.index)
            },
        )
    return context(bindings) { appliedUseCode() }
}

/** Interfaces, abstract and private classes, and parameters with several compiled bounds have no native binding. */
internal fun KSClassDeclaration.supportsNativeBinding(): Boolean =
    classKind != ClassKind.INTERFACE &&
        Modifier.ABSTRACT !in modifiers &&
        Modifier.PRIVATE !in modifiers &&
        typeParameters.none { parameter -> parameter.compiledBounds().count() > 1 }

private val KSClassDeclaration.serialKey: String
    get() = serialName ?: simpleName.asString()
