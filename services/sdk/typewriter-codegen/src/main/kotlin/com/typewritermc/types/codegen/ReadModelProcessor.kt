package com.typewritermc.types.codegen

import com.google.devtools.ksp.getClassDeclarationByName
import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.squareup.kotlinpoet.ANY
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.MAP
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STRING
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.squareup.kotlinpoet.WildcardTypeName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.argument
import com.typewritermc.codegen.declarationCode
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.listCode
import com.typewritermc.codegen.mapCode
import com.typewritermc.codegen.rawAnnotation
import com.typewritermc.codegen.serialName
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypewriterReadModels
import com.typewritermc.types.TypewriterString
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.KspTypeGraphConverter
import com.typewritermc.types.ksp.OwnedFieldDeclaration
import com.typewritermc.types.ksp.declaredTypeIdentity
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import kotlin.uuid.Uuid
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Generates the finite canonical expression model without publishing authoring declarations.
 *
 * Every class reachable from the `@TypewriterReadModels` roots receives a `typewriter.read` identity, except declared
 * `@TypewriterType` classes, which keep their declared identity so values such as `Color` match the authored catalog.
 */
internal class ReadModelProcessor(
    private val output: CodeGenerator,
    private val logger: KSPLogger,
) {
    private var generated = false

    fun process(resolver: Resolver) {
        if (generated) return
        val carriers =
            resolver
                .getSymbolsWithAnnotation(TypewriterReadModels::class)
                .filterIsInstance<KSClassDeclaration>()
                .sortedBy { it.qualifiedName!!.asString() }
                .toList()
        if (carriers.isEmpty()) return
        val roots =
            carriers.flatMap { carrier ->
                (carrier.rawAnnotation(TypewriterReadModels::class)?.argument("types") as List<*>)
                    .filterIsInstance<KSType>()
                    .map { it.declaration as KSClassDeclaration }
            }
        val definitions = linkedMapOf<TypeDefinitionId, TypeDefinition>()
        val declarations = linkedMapOf<TypeDefinitionId, KSClassDeclaration>()
        val fields = linkedMapOf<TypeDefinitionId, List<OwnedFieldDeclaration>>()
        val pending = ArrayDeque(roots.sortedBy { it.qualifiedName!!.asString() })
        val seen = mutableSetOf<String>()
        while (pending.isNotEmpty()) {
            val declaration = pending.removeFirst()
            if (!seen.add(declaration.qualifiedName!!.asString())) continue
            when (
                val result =
                    KspTypeGraphConverter(identityPolicy = { source ->
                        source.readModelIdentity()
                    }).convertDeclaration(declaration)
            ) {
                is KspTypeConversionResult.Failure -> {
                    result.diagnostics.forEach { logger.error(it.toString(), declaration) }
                    return
                }

                is KspTypeConversionResult.Success -> {
                    result.definitions.forEach { definitions[it.id] = it }
                    declarations.putAll(result.declarations)
                    fields.putAll(result.ownedFields)
                    result.declarations.values.sortedBy { it.qualifiedName!!.asString() }.forEach { source ->
                        pending.addAll(source.getSealedSubclasses().sortedBy { it.qualifiedName!!.asString() }.toList())
                    }
                }
            }
        }
        generated = true
        val sortedDeclarations = declarations.toSortedMap(compareBy { it.toString() })
        val references = context(resolver) { declarations.references() }
        val file =
            context(references) {
                GeneratedFile
                    .builder(PACKAGE, "CanonicalReadModels")
                    .addType(registry(roots, definitions.values.sortedBy { it.id.toString() }, sortedDeclarations, fields))
                    .apply {
                        sortedDeclarations.forEach { (id, declaration) ->
                            if (declaration.typeParameters.isNotEmpty() ||
                                definitions.getValue(id).representation !is RepresentationTemplate.Record
                            ) {
                                return@forEach
                            }
                            fields[id].orEmpty().forEach { field -> declaration.fieldExpression(field)?.let(::addProperty) }
                        }
                    }.build()
            }
        file.writeTo(output, Dependencies.ALL_FILES)
        output.createNewFile(Dependencies.ALL_FILES, "", "canonical-read-models", "json").bufferedWriter().use {
            it.write(manifest(definitions, sortedDeclarations, fields))
        }
    }

    /** Declared types reachable from read models reference their generated definition; read identities are literal. */
    context(resolver: Resolver)
    private fun Map<TypeDefinitionId, KSClassDeclaration>.references(): DefinitionReferences {
        val owners =
            entries
                .filter { (id, _) -> id.type is TypeId.Declared }
                .mapNotNull { (id, declaration) ->
                    val definition = SdkNames.of(declaration).definition
                    (id to definition).takeIf {
                        resolver.getClassDeclarationByName(definition.canonicalName) != null ||
                            declaration.origin.name == "KOTLIN"
                    }
                }.toMap()
        return DefinitionReferences(owners, unowned = TypeDefinitionId::declarationCode)
    }

    context(_: DefinitionReferences)
    private fun registry(
        roots: List<KSClassDeclaration>,
        definitions: List<TypeDefinition>,
        declarations: Map<TypeDefinitionId, KSClassDeclaration>,
        fields: Map<TypeDefinitionId, List<OwnedFieldDeclaration>>,
    ): TypeSpec =
        TypeSpec
            .objectBuilder("CanonicalReadModels")
            .superclass(Api.CanonicalReadModelRegistry)
            .addSuperclassConstructorParameter("definitions = %L", definitions.map { it.kotlinCode() }.listCode())
            .addSuperclassConstructorParameter(
                "descriptors = %L",
                declarations
                    .map { (id, declaration) ->
                        descriptor(declaration, id, fields[id].orEmpty(), definitions.single { it.id == id })
                    }.listCode(),
            ).addProperties(
                roots.map { root ->
                    val type = root.toClassName()
                    PropertySpec
                        .builder(
                            root.simpleName.asString().replaceFirstChar(Char::lowercaseChar),
                            Api.CanonicalReadModel.parameterizedBy(type),
                        ).initializer("model(%T::class)", type)
                        .build()
                },
            ).build()

    context(_: DefinitionReferences)
    private fun descriptor(
        declaration: KSClassDeclaration,
        id: TypeDefinitionId,
        fields: List<OwnedFieldDeclaration>,
        definition: TypeDefinition,
    ): CodeBlock {
        val name = declaration.toClassName()
        val members: List<CodeBlock> =
            when (val representation = definition.representation) {
                is RepresentationTemplate.Record -> {
                    val getters =
                        fields.map { field ->
                            CodeBlock.of("%S", field.name) to CodeBlock.of("{ value: Any·->♢(value as %T).%N }", name, field.sourceName)
                        }
                    val constructor =
                        if (representation.abstract) {
                            CodeBlock.of("null")
                        } else {
                            val arguments =
                                declaration.primaryConstructor?.parameters.orEmpty().map { parameter ->
                                    val property = parameter.name!!.asString()
                                    val key = fields.first { it.sourceName == property }.name
                                    CodeBlock.of("%N = values.getValue(%S) as %T", property, key, parameter.type.resolve().toTypeName())
                                }
                            CodeBlock.of(
                                "{ values: %T·->♢%T(%L) }",
                                MAP.parameterizedBy(STRING, ANY.copy(nullable = true)),
                                name,
                                arguments.joinToCode(",♢"),
                            )
                        }
                    listOf(CodeBlock.of("fields = %L", getters.mapCode()), CodeBlock.of("construct = %L", constructor))
                }

                is RepresentationTemplate.Enumeration -> {
                    val cases =
                        declaration.declarations
                            .filterIsInstance<KSClassDeclaration>()
                            .filter { it.classKind == ClassKind.ENUM_ENTRY }
                            .toList()
                    val encode = cases.map { CodeBlock.of("%T.%N·->♢%S", name, it.simpleName.asString(), it.serialKey) }.joinToCode(";♢")
                    val decode = cases.map { CodeBlock.of("%S·->♢%T.%N", it.serialKey, name, it.simpleName.asString()) }.joinToCode(";♢")
                    listOf(
                        CodeBlock.of("unwrap = { value·->♢when (value as %T) { %L } }", name, encode),
                        CodeBlock.of("wrap = { value·->♢when (value) { %L;♢else·->♢error(%S) } }", decode, "Unknown canonical enum case"),
                    )
                }

                is RepresentationTemplate.Scalar -> {
                    if (declaration.classKind == ClassKind.OBJECT) {
                        listOf(CodeBlock.of("unwrap = { Unit }"), CodeBlock.of("wrap = { %T }", name))
                    } else {
                        val parameter = declaration.primaryConstructor!!.parameters.single()
                        val property = parameter.name!!.asString()
                        val stored = parameter.type.resolve().toTypeName()
                        val text = declaration.annotation<TypewriterString>() != null
                        val getter = CodeBlock.of("(value as %T).%N%L", name, property, if (text) ".toString()" else "")
                        val convert =
                            if (stored == UUID) CodeBlock.of("%T.parse(value as String)", UUID) else CodeBlock.of("value as %T", stored)
                        listOf(CodeBlock.of("unwrap = { value·->♢%L }", getter), CodeBlock.of("wrap = { value·->♢%T(%L) }", name, convert))
                    }
                }

                else -> {
                    error("Canonical native model $name has unsupported representation $representation")
                }
            }
        return CodeBlock.of(
            "%T(%T::class,♢%L,♢%L)",
            Api.CanonicalReadDescriptor,
            name,
            id.kotlinCode(),
            members.joinToCode(",♢"),
        )
    }

    /** A typed field read on canonical model expressions, for example `expr.definition`. */
    private fun KSClassDeclaration.fieldExpression(field: OwnedFieldDeclaration): PropertySpec? {
        val property = getAllProperties().firstOrNull { it.simpleName.asString() == field.sourceName } ?: return null
        val name = toClassName()
        val missing = TypeVariableName("M", Api.MissingPolicy)
        return PropertySpec
            .builder(field.sourceName, Api.Expr.parameterizedBy(property.type.resolve().toTypeName(), Api.MayBeMissing))
            .addAnnotation(
                com.typewritermc.types.codegen.emit
                    .jvmName("${name.canonicalName.replace('.', '_')}_${field.sourceName}", getter = true),
            ).addTypeVariable(missing)
            .receiver(Api.Expr.parameterizedBy(WildcardTypeName.producerOf(name.copy(nullable = true)), missing))
            .getter(FunSpec.getterBuilder().addStatement("return %M(%S)", Api.expressionField, field.name).build())
            .build()
    }

    private fun manifest(
        definitions: Map<TypeDefinitionId, TypeDefinition>,
        declarations: Map<TypeDefinitionId, KSClassDeclaration>,
        fields: Map<TypeDefinitionId, List<OwnedFieldDeclaration>>,
    ): String =
        buildString {
            append("{\"definitions\":[")
            append(
                definitions.values.sortedBy { it.id.toString() }.joinToString { definition ->
                    skirout.editor.v1.type_catalog.TypeDefinition.serializer.toJsonCode(
                        SkirTypeCodec.encode(definition).getOrThrow(),
                        build.skir.JsonFlavor.READABLE,
                    )
                },
            )
            append("],\"models\":[")
            append(
                declarations.entries.joinToString { (id, declaration) ->
                    val identity =
                        skirout.editor.v1.type_catalog.TypeDefinitionId.serializer.toJsonCode(
                            SkirTypeCodec.encode(definitions.getValue(id)).getOrThrow().id,
                            build.skir.JsonFlavor.READABLE,
                        )
                    val recordFields =
                        if (definitions
                                .getValue(
                                    id,
                                ).representation is RepresentationTemplate.Record
                        ) {
                            fields[id].orEmpty()
                        } else {
                            emptyList()
                        }
                    "{\"native\":${declaration.qualifiedName!!.asString().jsonString()},\"definition\":$identity,\"fields\":[" +
                        recordFields.joinToString { field ->
                            "{\"name\":${field.name.jsonString()},\"source\":${field.sourceName.jsonString()}}"
                        } +
                        "]}"
                },
            )
            append("]}")
        }

    private companion object {
        const val PACKAGE = "com.typewritermc.expression"
        val UUID: ClassName = ClassName("kotlin.uuid", Uuid::class.simpleName!!)
    }
}

/** Declared types keep their identity; every other read model class is named in the `typewriter.read` namespace. */
private fun KSClassDeclaration.readModelIdentity(): TypeDefinitionId =
    declaredTypeIdentity() ?: TypeDefinitionId(TypeId.Qualified("typewriter.read", toClassName().canonicalName), 1)

private val KSClassDeclaration.serialKey: String
    get() = serialName ?: simpleName.asString()

/** A JSON string literal; read model names and field keys are Kotlin identifiers, so only quoting is needed. */
private fun String.jsonString(): String = "\"" + replace("\\", "\\\\").replace("\"", "\\\"") + "\""
