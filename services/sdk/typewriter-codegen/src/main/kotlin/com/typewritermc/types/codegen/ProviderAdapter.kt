package com.typewritermc.types.codegen

import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.listCode
import com.typewritermc.codegen.namedArguments
import com.typewritermc.codegen.sentenceCase
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.PresentationId
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.toTemplate
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * The generated provider of one authored object for one generated contract.
 *
 * The provider is where the owner's concrete type arguments (operations) and runtime services (presentation) meet the
 * generic loader, so there is one per authored object and contract, as for capabilities and registrars.
 */
internal class ProviderAdapter(
    owner: KSClassDeclaration,
    target: KSClassDeclaration,
    kind: GeneratedContract.Kind,
) {
    private val ownerClass = owner.toClassName()
    private val targetNames = SdkNames.of(target)
    private val targetParameters = target.typeParameters.size

    /** Unique per package: owner nested name, target and contract kind. */
    val name: ClassName =
        ClassName(ownerClass.packageName, "${ownerClass.simpleNames.joinToString("")}_${targetNames.baseName}${kind.suffix}Provider")

    /** Stable presentation identity derived from declarations, not from the adapter class name. */
    private val presentationName = "${ownerClass.canonicalName}/${targetNames.baseName}"

    fun configuration(): FileSpec =
        file(
            TypeSpec
                .classBuilder(name)
                .addSuperinterface(Api.GeneratedConfigurationProvider)
                .addProperty(targetProperty())
                .addFunction(
                    FunSpec
                        .builder("collect")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("scope", Api.ConfigurationCollectionScope)
                        .returns(Api.CollectedConfiguration)
                        .addStatement("with(%T) { %T(scope).configure() }", ownerClass, targetNames.configurationScopeImpl)
                        .addStatement("return scope.collected()")
                        .build(),
                ),
        )

    fun presentation(): FileSpec =
        file(
            TypeSpec
                .classBuilder(name)
                .primaryConstructor(FunSpec.constructorBuilder().addParameter("runtime", Api.PresentationRuntime).build())
                .addProperty(PropertySpec.builder("runtime", Api.PresentationRuntime, KModifier.PRIVATE).initializer("runtime").build())
                .addSuperinterface(Api.GeneratedPresentationProvider)
                .addProperty(
                    PropertySpec
                        .builder("reference", Api.PresentationReference, KModifier.OVERRIDE)
                        .getter(FunSpec.getterBuilder().addStatement("return %T", ownerClass).build())
                        .build(),
                ).addFunction(
                    FunSpec
                        .builder("descriptor")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("origin", Api.ProviderOrigin)
                        .returns(PresentationDescriptor::class.asClassName())
                        .addCode(
                            """
                            |return with(%T) {
                            |    %T(
                            |        id = %T(origin.artifact.value,♢%S),
                            |        owner = origin.owner,
                            |        target = %T(%L),
                            |        roles = roles,
                            |        priority = priority,
                            |    ).also { runtime.register(this,♢it) }
                            |}
                            |
                            """.trimMargin(),
                            ownerClass,
                            PresentationDescriptor::class.asClassName(),
                            PresentationId::class,
                            presentationName,
                            PresentationTarget.Named::class,
                            symbolicTarget(),
                        ).build(),
                ).addFunction(
                    FunSpec
                        .builder("build")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("binding", Api.PresentationBuildBinding)
                        .returns(Api.PresentationBuildResult)
                        .addStatement(
                            "return runtime.build(binding) { build·->♢with(%T) { %T(build).present() } }",
                            ownerClass,
                            targetNames.presentationScopeImpl,
                        ).build(),
                ),
        )

    fun check(): FileSpec =
        file(
            TypeSpec
                .classBuilder(name)
                .addSuperinterface(Api.GeneratedCheckProvider)
                .addProperty(targetProperty())
                .addFunction(
                    FunSpec
                        .builder("register")
                        .addModifiers(KModifier.OVERRIDE)
                        .receiver(Api.RealmChecks)
                        .addStatement("with(%T) { this@register.register() }", ownerClass)
                        .build(),
                ),
        )

    /**
     * The provider of one operation object. [application] is the closed resource application an `XOperation` contract
     * targets, with [arguments] its native then draft type arguments, or null for the root `ResourceOperation`, which
     * applies to any resource. [input] is the operation's native input type and [inputUse] its portable type, or null
     * for [Unit]. The default label is the object name in sentence case.
     */
    context(_: DefinitionReferences)
    fun operation(
        application: TypeUse.Named?,
        arguments: List<TypeName>,
        projections: List<CodeBlock>,
        input: TypeName,
        inputUse: TypeUse.Named?,
    ): FileSpec {
        val draft: TypeName
        val target: CodeBlock
        val subjects: CodeBlock
        val spec: TypeName
        if (application == null) {
            draft = Api.ResourceDraft
            target = CodeBlock.of("%T", ResourceTarget.AnyResource::class)
            subjects = CodeBlock.of("%T", Api.AnyResourceSubjects)
            spec = Api.ResourceOperationSpecImpl.parameterizedBy(input)
        } else {
            draft = if (targetParameters == 0) targetNames.draft else targetNames.exactDraft.parameterizedBy(arguments)
            target = CodeBlock.of("%T(%L)", ResourceTarget.Type::class, application.toTemplate().kotlinCode())
            val projection =
                if (targetParameters == 0) {
                    CodeBlock.of("%T", targetNames.draftProjection)
                } else {
                    CodeBlock.of(
                        "%M(%L,♢%T(%L)::bind)",
                        Api.draftViewProjection,
                        application.kotlinCode(),
                        targetNames.exactDraftType.parameterizedOrSelf(arguments),
                        projections.joinToCode(",♢"),
                    )
                }
            subjects = CodeBlock.of("%M(%L)", Api.projectedSubjects, projection)
            spec = targetNames.operationSpecImpl.parameterizedOrSelf(arguments + input)
        }
        val inputCode =
            if (inputUse ==
                null
            ) {
                CodeBlock.of("%T", Api.OperationInputNone)
            } else {
                CodeBlock.of("%T(%L)", Api.OperationInputTyped, inputUse.kotlinCode())
            }
        return file(
            TypeSpec
                .classBuilder(name)
                .addSuperinterface(Api.GeneratedResourceOperationProvider)
                .addFunction(
                    FunSpec
                        .builder("contribute")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("origin", Api.ProviderOrigin)
                        .returns(Api.OperationDeclaration)
                        .addCode(
                            "return %M<%T,♢%T>%L { spec ->\n⇥with(%T) { %T(spec).declare() }\n⇤}\n",
                            Api.collectOperation,
                            draft,
                            input,
                            namedArguments(
                                "origin" to CodeBlock.of("origin"),
                                "declaration" to CodeBlock.of("%S", ownerClass.canonicalName),
                                "target" to target,
                                "subjects" to subjects,
                                "input" to inputCode,
                                "defaultLabel" to CodeBlock.of("%S", ownerClass.simpleName.sentenceCase()),
                            ),
                            ownerClass,
                            spec,
                        ).build(),
                ),
        )
    }

    /**
     * The display provider of an owner implementing `XDisplay` with [arguments], or the root `ResourceDisplay`
     * when the target is the unpublished `Resource` marker, which applies to any resource.
     */
    fun display(arguments: List<TypeName>): FileSpec {
        val anyResource = targetNames.source == Resource::class.asClassName()
        val target =
            if (anyResource) {
                CodeBlock.of("%T", ResourceTarget.AnyResource::class)
            } else {
                CodeBlock.of("%T(%L)", ResourceTarget.Type::class, symbolicTarget())
            }
        val scope =
            if (anyResource) {
                CodeBlock.of("%T", Api.ResourceDisplaySubject)
            } else {
                CodeBlock.of("%T()", targetNames.displayScopeImpl.parameterizedOrSelf(arguments))
            }
        return file(
            TypeSpec
                .classBuilder(name)
                .addSuperinterface(Api.GeneratedResourceDisplayProvider)
                .addProperty(
                    PropertySpec
                        .builder("target", ResourceTarget::class, KModifier.OVERRIDE)
                        .getter(FunSpec.getterBuilder().addStatement("return %L", target).build())
                        .build(),
                ).addFunction(
                    FunSpec
                        .builder("formulas")
                        .addModifiers(KModifier.OVERRIDE)
                        .returns(Api.DisplayFormulas)
                        .addCode(
                            """
                            |return with(%T) {
                            |    val scope = %L
                            |    %T(label = scope.label(),♢accent = scope.accent(),♢icon = scope.icon())
                            |}
                            |
                            """.trimMargin(),
                            ownerClass,
                            scope,
                            Api.DisplayFormulas,
                        ).build(),
                ),
        )
    }

    private fun targetProperty(): PropertySpec =
        PropertySpec
            .builder("target", TypeDefinitionId::class, KModifier.OVERRIDE)
            .initializer("%T.id", targetNames.definition)
            .build()

    /** `TypeTemplate.Named(TargetDefinition.id, [Parameter(ParameterKey(TargetDefinition.id, i))...])`. */
    private fun symbolicTarget(): CodeBlock {
        val id = CodeBlock.of("%T.id", targetNames.definition)
        val parameters =
            (0 until targetParameters).map { index ->
                CodeBlock.of("%T(%T(%L,♢%L))", TypeTemplate.Parameter::class, ParameterKey::class, id, index)
            }
        return CodeBlock.of("%T(%L,♢%L)", TypeTemplate.Named::class, id, parameters.listCode())
    }

    private fun file(type: TypeSpec.Builder): FileSpec =
        GeneratedFile.builder(name.packageName, name.simpleName).addType(type.build()).build()
}
