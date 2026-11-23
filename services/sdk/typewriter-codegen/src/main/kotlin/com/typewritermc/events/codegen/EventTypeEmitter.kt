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
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.implements
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/** Emits what the event runtime needs of a Typewriter type whose SDK this compilation emits: an `EventShape` engine part for each concrete event. */
internal class EventTypeEmitter(
    private val output: GeneratedOutput,
    private val engineParts: EnginePartProviderProcessor,
    private val logger: KSPLogger,
) {
    fun emit(declaration: KSClassDeclaration) {
        if (declaration.isEvent() && declaration.isConcrete()) shape(declaration)
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
}
