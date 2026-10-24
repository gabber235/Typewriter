package com.typewritermc.types.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.Modifier
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.kotlinLiteral
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.KspTypeGraphConverter
import com.typewritermc.types.ksp.OwnedFieldDeclaration
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow

/** Generates the finite canonical expression model without publishing authoring declarations. */
internal class ReadModelProcessor(
    private val output: CodeGenerator,
    private val logger: KSPLogger,
) {
    private var generated = false

    fun process(resolver: Resolver) {
        if (generated) return
        val carriers =
            resolver
                .getSymbolsWithAnnotation(
                    "com.typewritermc.types.TypewriterReadModels",
                ).filterIsInstance<KSClassDeclaration>()
                .sortedBy { it.qualifiedName!!.asString() }
                .toList()
        if (carriers.isEmpty()) return
        val roots =
            carriers.flatMap { carrier ->
                carrier.annotations
                    .first {
                        it.annotationType
                            .resolve()
                            .declaration.qualifiedName
                            ?.asString() ==
                            "com.typewritermc.types.TypewriterReadModels"
                    }.arguments
                    .first()
                    .value
                    .let { it as List<*> }
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
                        TypeDefinitionId(TypeId.Qualified("typewriter.read", source.qualifiedName!!.asString()), 1)
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
        val source =
            buildString {
                appendLine("package com.typewritermc.expression")
                appendLine("import com.typewritermc.expression.field")
                appendLine("object CanonicalReadModels : CanonicalReadModelRegistry(")
                appendLine("    definitions = listOf(")
                definitions.values.sortedBy { it.id.toString() }.forEach { appendLine("        ${it.kotlinCode()},") }
                appendLine("    ),")
                appendLine("    descriptors = listOf(")
                declarations.toSortedMap(compareBy { it.toString() }).forEach { (id, declaration) ->
                    appendLine(descriptor(declaration, definitions.getValue(id), fields[id].orEmpty()))
                }
                appendLine("    ),")
                appendLine(") {")
                roots.forEach { root ->
                    val qualified = root.qualifiedName!!.asString()
                    val property = root.simpleName.asString().replaceFirstChar(Char::lowercaseChar)
                    appendLine("    val $property: CanonicalReadModel<$qualified> = model($qualified::class)")
                }
                appendLine("}")
                declarations.toSortedMap(compareBy { it.toString() }).forEach { (id, declaration) ->
                    val qualified = declaration.qualifiedName!!.asString()
                    if (declaration.typeParameters.isNotEmpty() ||
                        definitions.getValue(id).representation !is RepresentationTemplate.Record
                    ) {
                        return@forEach
                    }
                    fields[id].orEmpty().forEach { field ->
                        val property =
                            declaration.getAllProperties().firstOrNull { it.simpleName.asString() == field.sourceName } ?: return@forEach
                        val type = property.type.resolve().sourceName()
                        val getter = qualified.replace('.', '_') + "_" + field.sourceName
                        appendLine("@get:kotlin.jvm.JvmName(\"$getter\")")
                        appendLine("val <M : MissingPolicy> Expr<out $qualified?, M>.`${field.sourceName}`: Expr<$type, MayBeMissing>")
                        appendLine("    get() = field(${field.name.kotlinLiteral()})")
                    }
                }
            }
        output
            .createNewFile(
                Dependencies.ALL_FILES,
                "com.typewritermc.expression",
                "CanonicalReadModels",
            ).bufferedWriter()
            .use { it.write(source) }
        val manifest =
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
                    declarations.toSortedMap(compareBy { it.toString() }).entries.joinToString { (id, declaration) ->
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
                        "{\"native\":${declaration.qualifiedName!!.asString().kotlinLiteral()},\"definition\":$identity,\"fields\":[" +
                            recordFields.joinToString { field ->
                                "{\"name\":${field.name.kotlinLiteral()},\"source\":${field.sourceName.kotlinLiteral()}}"
                            } +
                            "]}"
                    },
                )
                append("]}")
            }
        output.createNewFile(Dependencies.ALL_FILES, "", "canonical-read-models", "json").bufferedWriter().use { it.write(manifest) }
    }

    private fun descriptor(
        declaration: KSClassDeclaration,
        definition: TypeDefinition,
        fields: List<OwnedFieldDeclaration>,
    ): String {
        val name = declaration.qualifiedName!!.asString()
        val prefix = "CanonicalReadDescriptor($name::class, ${definition.id.kotlinCode()}, "
        return when (val representation = definition.representation) {
            is RepresentationTemplate.Record -> {
                val getters =
                    fields.joinToString { field ->
                        "${field.name.kotlinLiteral()} to { value: Any -> (value as $name).`${field.sourceName}` }"
                    }
                val constructor =
                    if (representation.abstract) {
                        "null"
                    } else {
                        val arguments =
                            declaration.primaryConstructor?.parameters.orEmpty().joinToString { parameter ->
                                val property = parameter.name!!.asString()
                                val key = fields.first { it.sourceName == property }.name
                                "`$property` = values.getValue(${key.kotlinLiteral()}) as ${parameter.type.resolve().sourceName()}"
                            }
                        "{ values: Map<String, Any?> -> $name($arguments) }"
                    }
                "        ${prefix}fields = mapOf($getters), construct = $constructor),"
            }

            is RepresentationTemplate.Enumeration -> {
                val cases =
                    declaration.declarations
                        .filterIsInstance<KSClassDeclaration>()
                        .filter { it.classKind == ClassKind.ENUM_ENTRY }
                        .toList()
                val encode =
                    cases.joinToString(
                        "; ",
                    ) { case -> "$name.${case.simpleName.asString()} -> ${case.serialName().kotlinLiteral()}" }
                val decode =
                    cases.joinToString(
                        "; ",
                    ) { case -> "${case.serialName().kotlinLiteral()} -> $name.${case.simpleName.asString()}" }
                "        ${prefix}unwrap = { value -> when (value as $name) { $encode } }, wrap = { value -> when (value) { $decode; else -> error(\"Unknown canonical enum case\") } }),"
            }

            is RepresentationTemplate.Scalar -> {
                if (declaration.classKind == ClassKind.OBJECT) return "        ${prefix}unwrap = { Unit }, wrap = { $name }),"
                val parameter = declaration.primaryConstructor!!.parameters.single()
                val property = parameter.name!!.asString()
                val scalarType = parameter.type.resolve().sourceName()
                val text =
                    declaration.annotations.any {
                        it.annotationType
                            .resolve()
                            .declaration.qualifiedName
                            ?.asString() ==
                            "com.typewritermc.types.TypewriterString"
                    }
                val getter = "(value as $name).`$property`" + if (text) ".toString()" else ""
                val convert = if (scalarType == "kotlin.uuid.Uuid") "kotlin.uuid.Uuid.parse(value as String)" else "value as $scalarType"
                "        ${prefix}unwrap = { value -> $getter }, wrap = { value -> $name($convert) }),"
            }

            else -> {
                error("Canonical native model $name has unsupported representation $representation")
            }
        }
    }
}

private fun KSClassDeclaration.serialName(): String =
    annotations
        .firstOrNull {
            it.annotationType
                .resolve()
                .declaration.qualifiedName
                ?.asString() == "kotlinx.serialization.SerialName"
        }?.arguments
        ?.first()
        ?.value as? String ?: simpleName.asString()

private fun KSType.sourceName(): String {
    val declarationName = declaration.qualifiedName?.asString() ?: declaration.simpleName.asString()
    val parameters =
        if (arguments.isEmpty()) {
            ""
        } else {
            arguments.joinToString(prefix = "<", postfix = ">") { argument ->
                argument.type?.resolve()?.sourceName() ?: "*"
            }
        }
    return declarationName + parameters + if (nullability.name == "NULLABLE") "?" else ""
}
