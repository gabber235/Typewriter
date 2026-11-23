package com.typewritermc.events.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.getConstructors
import com.google.devtools.ksp.isPrivate
import com.google.devtools.ksp.isPublic
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.symbol.Origin
import com.squareup.kotlinpoet.ANY
import com.squareup.kotlinpoet.AnnotationSpec
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LIST
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.WildcardTypeName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.implements
import com.typewritermc.discovery.GeneratedProviderKind
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Emits an `EnginePartProvider` for each concrete class of this compilation that implements `EnginePart`. This is the
 * one processor that finds its declarations by supertype instead of by annotation, so implementing the interface is
 * the whole registration. The provider calls the part's one public constructor, asking the engine for each parameter.
 */
internal class EnginePartProviderProcessor(
    private val output: GeneratedOutput,
    private val logger: KSPLogger,
) {
    private val seen = mutableSetOf<String>()

    /** Provides every engine part declared in this round's own source files. */
    fun process(resolver: Resolver) {
        resolver
            .getAllFiles()
            .flatMap { classes(it.declarations) }
            .filter { it.origin == Origin.KOTLIN && it.isConcretePart() }
            .forEach { declaration ->
                val name = declaration.qualifiedName?.asString() ?: return@forEach
                if (seen.add(name)) provide(declaration)
            }
    }

    /**
     * Provides a part this compilation generates, such as a handler plan, built by its no argument constructor. Its
     * file only becomes a source in a later round, so it is provided here and skipped when a later round finds it.
     */
    fun provideGenerated(
        part: ClassName,
        supertypes: List<ClassName>,
        origin: KSDeclaration,
    ) {
        if (seen.add(part.canonicalName)) emit(part, listOf(part) + supertypes, CodeBlock.of(""), casts = false, origin)
    }

    private fun KSClassDeclaration.isConcretePart(): Boolean =
        classKind == ClassKind.CLASS &&
            Modifier.ABSTRACT !in modifiers &&
            Modifier.SEALED !in modifiers &&
            implements(Api.EnginePart)

    private fun provide(declaration: KSClassDeclaration) {
        if (declaration.isPrivate()) {
            logger.error("An engine part must be visible, so the engine can build it.", declaration)
            return
        }
        val constructor =
            declaration
                .getConstructors()
                .filter { it.isPublic() }
                .toList()
                .singleOrNull()
        if (constructor == null) {
            logger.error("An engine part needs exactly one public constructor, so the engine knows how to build it.", declaration)
            return
        }
        val part = declaration.toClassName()
        val binds = listOf(part) + declaration.getAllSuperTypes().mapNotNull { (it.declaration as? KSClassDeclaration)?.toClassName() }
        var casts = false
        val arguments =
            constructor.parameters
                .map { parameter ->
                    val type = parameter.type.resolve()
                    val erased = (type.declaration as KSClassDeclaration).toClassName()
                    val asked = CodeBlock.of("dependencies.get(%T::class)", erased)
                    if (type.arguments.isEmpty()) {
                        asked
                    } else {
                        casts = true
                        CodeBlock.of("%L as %T", asked, parameter.type.toTypeName())
                    }
                }.joinToCode(",\n")
        emit(part, binds, arguments, casts, declaration)
    }

    private fun emit(
        part: ClassName,
        supertypes: List<ClassName>,
        arguments: CodeBlock,
        casts: Boolean,
        origin: KSDeclaration,
    ) {
        val provider = ClassName(part.packageName, part.simpleNames.joinToString("_") + "EnginePartProvider")
        val binds =
            supertypes
                .filter { it != ANY }
                .distinct()
                .map { CodeBlock.of("%T::class", it) }
                .joinToCode(", ")
        val create =
            FunSpec
                .builder("create")
                .addModifiers(KModifier.OVERRIDE)
                .addParameter("dependencies", Api.EnginePartDependencies)
                .returns(Api.EnginePart)
                .addStatement("return %T(\n⇥%L\n⇤)", part, arguments)
        if (casts) create.addAnnotation(AnnotationSpec.builder(Suppress::class).addMember("%S", "UNCHECKED_CAST").build())
        val kClass = KClass::class.asClassName()
        val type =
            TypeSpec
                .classBuilder(provider)
                .addSuperinterface(Api.EnginePartProvider)
                .addProperty(
                    PropertySpec
                        .builder("type", kClass.parameterizedBy(WildcardTypeName.producerOf(Api.EnginePart)), KModifier.OVERRIDE)
                        .initializer("%T::class", part)
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("binds", LIST.parameterizedBy(kClass.parameterizedBy(STAR)), KModifier.OVERRIDE)
                        .initializer("listOf(%L)", binds)
                        .build(),
                ).addFunction(create.build())
                .build()
        output.provide(
            GeneratedFile.builder(provider.packageName, provider.simpleName).addType(type).build(),
            provider,
            GeneratedProviderKind.EnginePart,
            origin,
        )
    }
}

private fun classes(declarations: Sequence<KSDeclaration>): Sequence<KSClassDeclaration> =
    declarations.filterIsInstance<KSClassDeclaration>().flatMap { sequenceOf(it) + classes(it.declarations) }
