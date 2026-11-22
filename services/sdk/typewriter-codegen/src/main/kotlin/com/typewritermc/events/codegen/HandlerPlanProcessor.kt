package com.typewritermc.events.codegen

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeAlias
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.KSValueParameter
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.symbol.Variance
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ANY
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LIST
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.WildcardTypeName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.implements
import com.typewritermc.imprint.EntryTypeId
import com.typewritermc.imprint.HandledEntriesMetadata
import com.typewritermc.imprint.HandledEntriesMetadataCodec
import com.typewritermc.imprint.IMPRINT_HANDLED_ENTRIES_PATH
import com.typewritermc.types.canonicalText
import com.typewritermc.types.ksp.typeDefinitionIdentity
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Emits a handler plan for each top level `@Handler` function: an engine part that names the event it takes, describes
 * each parameter as a `Param`, and calls the function with the values the runtime resolved. A `Verdict` return makes a
 * `VerdictHandler`, a `Unit` return an `AfterHandler`. A handler on a configured event (`Tick<EveryTick>`) records its
 * configuration type as the plan's `HandlerConfig`, the (event, configuration type) pair the runtime builds demand from:
 * a Kotlin object is one configuration, an entry type one per published entry; any other configuration type is rejected.
 * A handler on a `Triggered<X>` step takes `TriggeredEvent<X>`, and its plan's first `Param.Triggered` asks the runtime
 * for the step to call it on. A parameter named like a field of the entries it reads is rejected: entry values are read
 * through the generated accessors.
 *
 * The entries a handler gives behaviour, its triggered entry and the entries of its candidates, are recorded for the
 * source part in [IMPRINT_HANDLED_ENTRIES_PATH], so the manifest can tell which part runs an entry.
 */
internal class HandlerPlanProcessor(
    private val output: GeneratedOutput,
    private val engineParts: EnginePartProviderProcessor,
    private val logger: KSPLogger,
) {
    private val seen = mutableSetOf<String>()
    private val handledEntries = sortedSetOf<String>()

    fun process(resolver: Resolver): List<KSAnnotated> {
        val deferred = mutableListOf<KSAnnotated>()
        resolver
            .getSymbolsWithAnnotation(Api.Handler.canonicalName)
            .filterIsInstance<KSFunctionDeclaration>()
            .forEach { function ->
                if (!function.validate()) {
                    deferred += function
                    return@forEach
                }
                val key = "${function.qualifiedName?.asString()}:${function.extensionReceiver}"
                if (seen.add(key)) context(resolver) { plan(function) }
            }
        return deferred
    }

    context(resolver: Resolver)
    private fun plan(function: KSFunctionDeclaration) {
        val receiver = eventReceiver(function) ?: return
        val event = checkNotNull(receiver.boundClass())
        val verdict = returnsVerdict(function) ?: return
        val generic = receiver.declaration as? KSTypeParameter
        val config =
            if (generic == null && event.implements(Api.ConfiguredEvent)) {
                receiver.configuration() ?: run {
                    logger.error("A configured event's configuration must be a Kotlin object or an entry type.", function)
                    return
                }
            } else {
                null
            }
        val eventType = eventType(receiver, event, generic)
        val triggered = receiver.triggeredEntry()
        val declared = params(function, receiver, generic, config) ?: return
        val params = listOfNotNull(triggered?.let { CodeBlock.of("%T.Triggered(%T::class)", Api.Param, it.toClassName()) }) + declared

        val plan = ClassName(function.packageName.asString(), "${event.simpleName.asString()}_${function.simpleName.asString()}Handler")
        val kind = if (verdict) Api.VerdictHandler else Api.AfterHandler
        val type = planType(plan, kind, function, receiver, eventType, verdict, params, config)
        if (output.write(GeneratedFile.builder(plan.packageName, plan.simpleName).addType(type).build(), function)) {
            engineParts.provideGenerated(plan, listOf(kind, Api.HandlerPlan, Api.EnginePart), function)
            handledEntries += handledEntryIds(receiver, config, function)
        }
    }

    /** The event a plan takes: `TriggeredEvent<X>` for a `Triggered<X>` receiver, the event class of a generic one, else the receiver. */
    private fun eventType(
        receiver: KSType,
        event: KSClassDeclaration,
        generic: KSTypeParameter?,
    ): TypeName =
        when {
            receiver.triggeredEntry() != null -> {
                Api.TriggeredEvent.parameterizedBy((receiver.bounded() as ParameterizedTypeName).typeArguments.single())
            }

            generic != null -> {
                event.starred()
            }

            else -> {
                receiver.bounded().copy(nullable = false)
            }
        }

    /** [function]'s receiver type when it is an event or a `Triggered` step; null, reported, otherwise. */
    private fun eventReceiver(function: KSFunctionDeclaration): KSType? {
        val receiver = function.extensionReceiver?.resolve()
        if (receiver?.boundClass()?.isEvent() != true && receiver?.triggeredEntry() == null) {
            logger.error("A handler's receiver must be an event or a Triggered step.", function)
            return null
        }
        return receiver
    }

    /**
     * Whether [function] is a verdict handler (returns a `Verdict`, never suspends) rather than an after handler (returns
     * `Unit`); null, reported, otherwise.
     */
    private fun returnsVerdict(function: KSFunctionDeclaration): Boolean? =
        when (
            function.returnType
                ?.resolve()
                ?.declaration
                ?.qualifiedName
                ?.asString()
        ) {
            Api.Verdict.canonicalName -> {
                if (Modifier.SUSPEND in function.modifiers) {
                    logger.error("A verdict handler decides inline and never suspends.", function)
                    null
                } else {
                    true
                }
            }

            "kotlin.Unit" -> {
                false
            }

            else -> {
                logger.error("A handler returns a Verdict to decide or Unit to run after the outcome.", function)
                null
            }
        }

    /** The `Param` of each of [function]'s parameters; null, each unmatched one reported, when any matches no kind. */
    context(resolver: Resolver)
    private fun params(
        function: KSFunctionDeclaration,
        receiver: KSType,
        generic: KSTypeParameter?,
        config: Configuration?,
    ): List<CodeBlock>? {
        val accessors = accessorsOf(function, receiver)
        val params =
            function.parameters.map { parameter ->
                val accessor = accessors[parameter.name?.asString()]
                if (accessor != null) {
                    logger.error(
                        "A handler reads entry values through accessors: read `$accessor` in the body instead of a parameter.",
                        parameter,
                    )
                    return@map null
                }
                classify(parameter, receiver, generic, config).also {
                    if (it == null) {
                        logger.error(
                            "A handler parameter must be a Candidate, Origin, Outcome, identity, configuration or trait interface.",
                            parameter,
                        )
                    }
                }
            }
        return if (null in params) null else params.filterNotNull()
    }

    /**
     * The accessor that reads each field a handler could mean by a parameter's name: a field of the triggered entry reads
     * bare, a field of a candidate's entry on that candidate.
     */
    private fun accessorsOf(
        function: KSFunctionDeclaration,
        receiver: KSType,
    ): Map<String, String> {
        val candidates =
            function.parameters.mapNotNull { parameter ->
                val type = parameter.type.resolve()
                if (type.declaration.qualifiedName?.asString() != Api.Candidate.canonicalName) return@mapNotNull null
                val entry =
                    type.arguments
                        .singleOrNull()
                        ?.type
                        ?.resolve()
                        ?.boundClass() ?: return@mapNotNull null
                parameter.name?.asString()?.let { name -> entry to "$name." }
            }
        return (listOfNotNull(receiver.triggeredEntry()?.let { it to "" }) + candidates)
            .flatMap { (entry, prefix) ->
                entry.getAllProperties().map { it.simpleName.asString() to "$prefix${it.simpleName.asString()}" }
            }.reversed()
            .toMap()
    }

    /** The generated plan class [plan] for [function]: its event, parameters, configuration and run. */
    private fun planType(
        plan: ClassName,
        kind: ClassName,
        function: KSFunctionDeclaration,
        receiver: KSType,
        eventType: TypeName,
        verdict: Boolean,
        params: List<CodeBlock>,
        config: Configuration?,
    ): TypeSpec {
        val kClass = KClass::class.asClassName()
        val eventKClass =
            if (eventType is ParameterizedTypeName) {
                CodeBlock.of("%T::class as %T", eventType.rawType, kClass.parameterizedBy(eventType))
            } else {
                CodeBlock.of("%T::class", eventType)
            }
        // A Triggered receiver is the scope the runtime built for the event, resolved as the first value.
        val triggered = receiver.triggeredEntry() != null
        val offset = if (triggered) 1 else 0
        val arguments =
            function.parameters
                .mapIndexed { index, parameter -> CodeBlock.of("values[%L] as %T", index + offset, parameter.type.resolve().bounded()) }
                .joinToCode(", ")
        val target = if (triggered) CodeBlock.of("(values[0] as %T)", receiver.bounded().copy(nullable = false)) else CodeBlock.of("event")
        val call = CodeBlock.of("%L.%M(%L)", target, MemberName(function.packageName.asString(), function.simpleName.asString()), arguments)
        val run =
            FunSpec
                .builder("run")
                .addModifiers(KModifier.OVERRIDE)
                .addParameter("event", eventType)
                .addParameter("values", LIST.parameterizedBy(ANY.copy(nullable = true)))
        if (verdict) {
            run.returns(Api.Verdict).addStatement("return %L", call)
        } else {
            run.addModifiers(KModifier.SUSPEND).addStatement("%L", call)
        }
        return TypeSpec
            .classBuilder(plan)
            .addSuperinterface(kind.parameterizedBy(eventType))
            .addProperty(
                PropertySpec
                    .builder("event", kClass.parameterizedBy(eventType), KModifier.OVERRIDE)
                    .initializer(eventKClass)
                    .build(),
            ).addProperty(
                PropertySpec
                    .builder("params", LIST.parameterizedBy(Api.Param), KModifier.OVERRIDE)
                    .initializer("listOf(\n⇥%L\n⇤)", params.joinToCode(",\n"))
                    .build(),
            ).apply {
                if (config != null) {
                    addProperty(
                        PropertySpec
                            .builder("config", Api.HandlerConfig.copy(nullable = true), KModifier.OVERRIDE)
                            .initializer(config.plan())
                            .build(),
                    )
                }
            }.addFunction(run.build())
            .build()
    }

    /** Writes the entries this source part's handlers give behaviour; a part without such handlers writes nothing. */
    fun finish() {
        if (handledEntries.isEmpty()) return
        output.resource(
            IMPRINT_HANDLED_ENTRIES_PATH,
            HandledEntriesMetadataCodec.encode(HandledEntriesMetadata(handledEntries.map(::EntryTypeId))),
        )
    }

    /**
     * The canonical type ids of the entries [function] gives behaviour: the triggered entry of its receiver, its entry
     * configuration type, and each candidate's entry. An entry whose declared id is invalid is skipped; the type processor reports it.
     */
    private fun handledEntryIds(
        receiver: KSType,
        config: Configuration?,
        function: KSFunctionDeclaration,
    ): List<String> {
        val candidates =
            function.parameters.mapNotNull { parameter ->
                val type = parameter.type.resolve()
                if (type.declaration.qualifiedName?.asString() != Api.Candidate.canonicalName) return@mapNotNull null
                type.arguments
                    .singleOrNull()
                    ?.type
                    ?.resolve()
                    ?.boundClass()
            }
        val configEntry = (config as? Configuration.Entries)?.entry
        return (
            listOfNotNull(
                receiver.triggeredEntry(),
                configEntry,
            ) + candidates
        ).mapNotNull { it.typeDefinitionIdentity()?.canonicalText }
    }

    /** The `Param.Candidate` of a `Candidate<E>` parameter of [type]; null when its entry type is unresolved. */
    private fun candidateParam(
        type: KSType,
        receiver: KSType,
        generic: KSTypeParameter?,
        config: Configuration?,
        optional: Boolean,
    ): CodeBlock? {
        val entry =
            type.arguments
                .singleOrNull()
                ?.type
                ?.resolve() ?: return null
        val entryClass = entry.boundClass() ?: return null
        val ofEvent =
            entry.arguments.any { argument ->
                val argumentType = argument.type?.resolve() ?: return@any false
                if (generic != null) {
                    (argumentType.declaration as? KSTypeParameter)?.name?.asString() == generic.name.asString()
                } else {
                    argumentType.bounded().copy(nullable = false) == receiver.bounded().copy(nullable = false)
                }
            }
        val ofConfig = (config as? Configuration.Entries)?.entry?.qualifiedName == entryClass.qualifiedName
        return CodeBlock.of(
            "%T.Candidate(%T::class, ofEvent = %L, ofConfig = %L, optional = %L)",
            Api.Param,
            entryClass.toClassName(),
            ofEvent,
            ofConfig,
            optional,
        )
    }

    /** The `Param` of [parameter], or null when it matches no kind. The order of the checks is the classification order. */
    context(resolver: Resolver)
    private fun classify(
        parameter: KSValueParameter,
        receiver: KSType,
        generic: KSTypeParameter?,
        config: Configuration?,
    ): CodeBlock? {
        val type = parameter.type.resolve()
        val optional = type.isMarkedNullable
        val declaration = type.declaration
        val name = declaration.qualifiedName?.asString()
        val classDeclaration = declaration as? KSClassDeclaration
        return when {
            name == Api.Candidate.canonicalName -> {
                candidateParam(type, receiver, generic, config, optional)
            }

            name == Api.EventOrigin.canonicalName -> {
                CodeBlock.of("%T.Origin(optional = %L)", Api.Param, optional)
            }

            name == Api.Outcome.canonicalName -> {
                CodeBlock.of("%T.Outcome", Api.Param)
            }

            classDeclaration != null && (name == Api.Identity.canonicalName || classDeclaration.implements(Api.Identity)) -> {
                CodeBlock.of("%T.Identity(%T::class, optional = %L)", Api.Param, classDeclaration.toClassName(), optional)
            }

            classDeclaration != null && receiver.isConfiguredBy(type) -> {
                CodeBlock.of("%T.Config(%T::class, optional = %L)", Api.Param, classDeclaration.toClassName(), optional)
            }

            classDeclaration?.classKind == ClassKind.INTERFACE -> {
                CodeBlock.of("%T.Trait(%T::class, optional = %L)", Api.Param, classDeclaration.toClassName(), optional)
            }

            else -> {
                null
            }
        }
    }

    /**
     * The configuration type of this configured event receiver: its type argument that the event is configured by,
     * when that argument is a Kotlin object or an entry class. Null for a type parameter or any other class, which
     * publication could not turn into configurations.
     */
    context(resolver: Resolver)
    private fun KSType.configuration(): Configuration? {
        val argument =
            arguments
                .mapNotNull { it.type?.resolve() }
                .firstOrNull { isConfiguredBy(it) } ?: return null
        val declaration = argument.declaration as? KSClassDeclaration ?: return null
        return when {
            declaration.classKind == ClassKind.OBJECT -> Configuration.Object(declaration)
            declaration.classKind == ClassKind.CLASS && declaration.implements(Api.Entry) -> Configuration.Entries(declaration)
            else -> null
        }
    }

    /** The configuration type of a configured event handler, as KSP found it. */
    private sealed interface Configuration {
        /** The `HandlerConfig` the plan carries. */
        fun plan(): CodeBlock

        data class Object(
            val instance: KSClassDeclaration,
        ) : Configuration {
            override fun plan(): CodeBlock = CodeBlock.of("%T.Object(%T)", Api.HandlerConfig, instance.toClassName())
        }

        data class Entries(
            val entry: KSClassDeclaration,
        ) : Configuration {
            override fun plan(): CodeBlock = CodeBlock.of("%T.Entries(%T::class)", Api.HandlerConfig, entry.toClassName())
        }
    }

    /** Whether this receiver is a `ConfiguredEvent` whose configuration is [type]. */
    context(resolver: Resolver)
    private fun KSType.isConfiguredBy(type: KSType): Boolean {
        val configured = resolver.getClassDeclarationByName(resolver.getKSNameFromString(Api.ConfiguredEvent.canonicalName)) ?: return false
        if (declaration !is KSClassDeclaration) return false
        val argument = resolver.getTypeArgument(resolver.createKSTypeReferenceFromKSType(type.makeNotNullable()), Variance.INVARIANT)
        return configured.asType(listOf(argument)).isAssignableFrom(this)
    }

    /** The entry class of a `Triggered<X>` receiver: X, or X's bound when X is a type parameter. */
    private fun KSType.triggeredEntry(): KSClassDeclaration? {
        if (declaration.qualifiedName?.asString() != Api.Triggered.canonicalName) return null
        return arguments
            .singleOrNull()
            ?.type
            ?.resolve()
            ?.boundClass()
    }
}

/** Whether this class is an event: `Event` itself or any of its subtypes. */
internal fun KSClassDeclaration.isEvent(): Boolean = qualifiedName?.asString() == Api.Event.canonicalName || implements(Api.Event)

/** The class of this type, or the class bound of a type parameter. */
internal fun KSType.boundClass(): KSClassDeclaration? =
    when (val declaration = declaration) {
        is KSClassDeclaration -> {
            declaration
        }

        is KSTypeParameter -> {
            declaration.bounds
                .firstOrNull()
                ?.resolve()
                ?.boundClass()
        }

        is KSTypeAlias -> {
            declaration.type.resolve().boundClass()
        }

        else -> {
            null
        }
    }

/** This class with every type parameter star projected, so a generic class can be named without its arguments. */
internal fun KSClassDeclaration.starred(): TypeName {
    val name = toClassName()
    return if (typeParameters.isEmpty()) name else name.parameterizedBy(typeParameters.map { STAR })
}

/** This type with each type parameter replaced by its bound, so a generic handler can be called from a plain class. */
internal fun KSType.bounded(): TypeName {
    val name: TypeName =
        when (val declaration = declaration) {
            is KSTypeParameter -> {
                declaration.bounds
                    .firstOrNull()
                    ?.resolve()
                    ?.bounded() ?: ANY.copy(nullable = true)
            }

            is KSClassDeclaration -> {
                val raw = declaration.toClassName()
                if (arguments.isEmpty()) {
                    raw
                } else {
                    raw.parameterizedBy(
                        arguments.map { argument ->
                            val argumentType = argument.type?.resolve()
                            if (argument.variance == Variance.STAR || argumentType == null) {
                                STAR
                            } else {
                                val bounded = argumentType.bounded()
                                when (argument.variance) {
                                    Variance.COVARIANT -> WildcardTypeName.producerOf(bounded)
                                    Variance.CONTRAVARIANT -> WildcardTypeName.consumerOf(bounded)
                                    else -> bounded
                                }
                            }
                        },
                    )
                }
            }

            else -> {
                toTypeName()
            }
        }
    return name.copy(nullable = name.isNullable || isMarkedNullable)
}
