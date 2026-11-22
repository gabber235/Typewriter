package com.typewritermc.events.codegen

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LIST
import com.squareup.kotlinpoet.ParameterizedTypeName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.squareup.kotlinpoet.ksp.toTypeParameterResolver
import com.squareup.kotlinpoet.ksp.toTypeVariableName
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.implements
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.containsParameter
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Emits what the event runtime needs of a Typewriter type whose SDK this compilation emits: an `EventShape` engine part
 * for each concrete event, and a `Candidate` accessor per `Var` field of each entry, so a handler reads `entry.cancel`
 * as a plain value. An accessor reads through the field's path in the entry's generated `XFields`.
 */
internal class EventTypeEmitter(
    private val output: GeneratedOutput,
    private val engineParts: EnginePartProviderProcessor,
    private val logger: KSPLogger,
) {
    fun emit(declaration: KSClassDeclaration) {
        if (declaration.isEvent() && declaration.isConcrete()) shape(declaration)
    }

    /** The `Candidate` accessors of an entry, each reading its `Var` field through the field's generated path. */
    fun accessors(model: SdkDeclaration) {
        if (model.source.implements(Api.Entry)) accessors(model.source, model)
    }

    private fun KSClassDeclaration.isConcrete(): Boolean =
        classKind == ClassKind.CLASS && Modifier.ABSTRACT !in modifiers && Modifier.SEALED !in modifiers

    private fun shape(declaration: KSClassDeclaration) {
        val identities =
            declaration
                .getAllProperties()
                .filter { property ->
                    val type = property.type.resolve().declaration as? KSClassDeclaration ?: return@filter false
                    type.qualifiedName?.asString() == Api.Identity.canonicalName || type.implements(Api.Identity)
                }.toList()
        val repeated =
            identities
                .groupBy {
                    it.type
                        .resolve()
                        .declaration.qualifiedName
                        ?.asString()
                }.values
                .flatMap { it.drop(1) }
        repeated.forEach { logger.error("An event names one field per identity kind until typed roles arrive.", it) }
        if (repeated.isNotEmpty()) return

        val event = declaration.starred()
        val name = declaration.toClassName()
        val shape = ClassName(name.packageName, name.simpleNames.joinToString("") + "EventShape")
        val kClass = KClass::class.asClassName()
        val eventKClass =
            if (event is ParameterizedTypeName) {
                CodeBlock.of(
                    "%T::class as %T",
                    name,
                    kClass.parameterizedBy(event),
                )
            } else {
                CodeBlock.of("%T::class", name)
            }
        val subject = identities.singleOrNull()?.let { CodeBlock.of("event.%N", it.simpleName.asString()) } ?: CodeBlock.of("null")
        val fields = identities.map { CodeBlock.of("event.%N", it.simpleName.asString()) }.joinToCode(", ")
        val type =
            TypeSpec
                .classBuilder(shape)
                .addSuperinterface(Api.EventShape.parameterizedBy(event))
                .addProperty(
                    PropertySpec.builder("event", kClass.parameterizedBy(event), KModifier.OVERRIDE).initializer(eventKClass).build(),
                ).addFunction(
                    FunSpec
                        .builder("subject")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("event", event)
                        .returns(Api.Identity.copy(nullable = true))
                        .addStatement("return %L", subject)
                        .build(),
                ).addFunction(
                    FunSpec
                        .builder("identities")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("event", event)
                        .returns(LIST.parameterizedBy(Api.Identity))
                        .addStatement("return listOfNotNull(%L)", fields)
                        .build(),
                ).build()
        if (output.write(GeneratedFile.builder(shape.packageName, shape.simpleName).addType(type).build(), declaration)) {
            engineParts.provideGenerated(shape, listOf(Api.EventShape, Api.EnginePart), declaration)
        }
    }

    private fun accessors(
        declaration: KSClassDeclaration,
        model: SdkDeclaration,
    ) {
        val parameters = declaration.typeParameters.toTypeParameterResolver()
        val variables =
            declaration.typeParameters.map {
                it.toTypeVariableName(parameters).let { variable ->
                    TypeVariableName(variable.name, variable.bounds)
                }
            }
        val name = declaration.toClassName()
        val entry = if (variables.isEmpty()) name else name.parameterizedBy(variables)
        val receiver = Api.Candidate.parameterizedBy(entry)
        val properties =
            declaration
                .getAllProperties()
                .mapNotNull { property ->
                    val type = property.type.resolve()
                    if (type.declaration.qualifiedName?.asString() != Api.Var.canonicalName) return@mapNotNull null
                    val value = type.arguments.firstOrNull()?.type ?: return@mapNotNull null
                    val field = property.simpleName.asString()
                    val path = model.fields.singleOrNull { it.property == field } ?: return@mapNotNull null
                    val result = value.toTypeName(parameters).copy(nullable = type.isMarkedNullable || value.resolve().isMarkedNullable)
                    val getter =
                        if (path.template.containsParameter) {
                            CodeBlock.of("return read(%T.%N) as %T", model.names.fields, field, result)
                        } else {
                            CodeBlock.of("return read(%T.%N)", model.names.fields, field)
                        }
                    PropertySpec
                        .builder(field, result)
                        .addTypeVariables(variables)
                        .receiver(receiver)
                        .getter(FunSpec.getterBuilder().addStatement("%L", getter).build())
                        .build()
                }.toList()
        if (properties.isEmpty()) return
        val file = GeneratedFile.builder(name.packageName, name.simpleNames.joinToString("") + "CandidateFields")
        properties.forEach(file::addProperty)
        output.write(file.build(), declaration)
    }
}
