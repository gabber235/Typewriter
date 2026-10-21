package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.BOOLEAN
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.INT
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LambdaTypeName
import com.squareup.kotlinpoet.ParameterSpec
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.SET
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.UNIT
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.codegen.FieldShape
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.nestedPresentationScopes
import com.typewritermc.types.codegen.parameterizedOrSelf
import com.typewritermc.types.codegen.presentationControl
import com.typewritermc.types.codegen.rawClass
import skirout.editor.v1.catalog.PresentationRole
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/** `XPresentation`, its typed scope and the scope implementation over the runtime build scope. */
internal object PresentationEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        val names = declaration.names
        val variables = declaration.typeVariables
        val scope = names.presentationScope.parameterizedOrSelf(variables)
        val implementation = names.presentationScopeImpl.parameterizedOrSelf(variables)
        val root = declaration.rootPresentation()
        addType(
            TypeSpec
                .interfaceBuilder(names.presentation)
                .addAnnotation(generatedContract(GeneratedContract.Kind.Presentation, declaration))
                .addTypeVariables(variables)
                .addSuperinterface(Api.PresentationReference)
                .addProperty(
                    PropertySpec
                        .builder("roles", SET.parameterizedBy(PresentationRole::class.asClassName()))
                        .getter(
                            FunSpec
                                .getterBuilder()
                                .addStatement(
                                    "return setOf(%T.INSPECTOR)",
                                    PresentationRole::class,
                                ).build(),
                        ).build(),
                ).addProperty(
                    PropertySpec.builder("priority", INT).getter(FunSpec.getterBuilder().addStatement("return 0").build()).build(),
                ).addFunction(
                    FunSpec
                        .builder("present")
                        .addModifiers(KModifier.ABSTRACT)
                        .receiver(scope)
                        .build(),
                ).build(),
        )
        val condition =
            LambdaTypeName.get(
                receiver = declaration.expressionsType,
                returnType = Api.Expr.parameterizedBy(BOOLEAN, Api.Handled),
            )
        val content = LambdaTypeName.get(receiver = scope, returnType = UNIT)
        addType(
            TypeSpec
                .interfaceBuilder(names.presentationScope)
                .addTypeVariables(variables)
                .addSuperinterface(Api.Layout)
                .addProperty(PropertySpec.builder("expressions", declaration.expressionsType).build())
                .apply { root?.let { addProperty(PropertySpec.builder("value", it.fieldType).build()) } }
                .apply { if (declaration.resource) addProperty(appearance()) }
                .addProperties(
                    declaration.fields.map { field ->
                        PropertySpec.builder(field.property, field.shape.presentedField()).build()
                    },
                ).addFunction(
                    FunSpec
                        .builder("showIf")
                        .addModifiers(KModifier.ABSTRACT)
                        .addParameter("condition", condition)
                        .addParameter(ParameterSpec.builder("whenFalse", content.copy(nullable = true)).defaultValue("null").build())
                        .addParameter("body", content)
                        .build(),
                ).build(),
        )
        val expressionsClass = KClass::class.asClassName().parameterizedBy(declaration.expressionsType)
        addType(
            TypeSpec
                .classBuilder(names.presentationScopeImpl)
                .addTypeVariables(variables)
                .primaryConstructor(FunSpec.constructorBuilder().addParameter("build", Api.PresentationBuildScope).build())
                .addProperty(PropertySpec.builder("build", Api.PresentationBuildScope, KModifier.PRIVATE).initializer("build").build())
                .addSuperinterface(Api.Layout, "build")
                .addSuperinterface(scope)
                .addInitializerBlock(CodeBlock.of("build.registerExpressions(%T)\n", names.expressionsFactory))
                .addProperty(
                    PropertySpec
                        .builder("expressions", declaration.expressionsType, KModifier.OVERRIDE)
                        .getter(
                            FunSpec
                                .getterBuilder()
                                .addStatement("return build.expressions(%T::class as %T)", names.expressions, expressionsClass)
                                .build(),
                        ).build(),
                ).apply {
                    root?.let {
                        addProperty(
                            PropertySpec
                                .builder("value", it.fieldType, KModifier.OVERRIDE)
                                .getter(
                                    FunSpec
                                        .getterBuilder()
                                        .addStatement(
                                            "return build.value(%T::class as %T,♢%L)",
                                            it.shape.presentationControl.rawClass,
                                            KClass::class.asClassName().parameterizedBy(it.shape.presentationControl),
                                            it.shape.nestedPresentationScopes(),
                                        ).build(),
                                ).build(),
                        )
                    }
                }.apply {
                    if (declaration.resource) {
                        addProperty(
                            PropertySpec
                                .builder("appearance", appearanceType, KModifier.OVERRIDE)
                                .getter(FunSpec.getterBuilder().addStatement("return build.resourceAppearance()").build())
                                .build(),
                        )
                    }
                }.addProperties(
                    declaration.fields.map { field ->
                        PropertySpec
                            .builder(field.property, field.shape.presentedField(), KModifier.OVERRIDE)
                            .getter(
                                FunSpec
                                    .getterBuilder()
                                    .addStatement(
                                        "return build.field(%S,♢%T::class as %T,♢%L)",
                                        field.name,
                                        field.shape.presentationControl.rawClass,
                                        KClass::class.asClassName().parameterizedBy(field.shape.presentationControl),
                                        field.shape.nestedPresentationScopes(),
                                    ).build(),
                            ).build()
                    },
                ).addFunction(
                    FunSpec
                        .builder("showIf")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("condition", condition)
                        .addParameter("whenFalse", content.copy(nullable = true))
                        .addParameter("body", content)
                        .addStatement("val expressions = build.expressions(%T::class as %T)", names.expressions, expressionsClass)
                        .addCode(
                            """
                            |val falseContent =
                            |    whenFalse?.let { content ->
                            |        { nested: %T·->♢with(%T(nested)) { content() } }
                            |    }
                            |build.conditional(condition = expressions.condition(),♢whenFalse = falseContent) { nested ->
                            |    with(%T(nested)) { body() }
                            |}
                            |
                            """.trimMargin(),
                            Api.PresentationBuildScope,
                            implementation,
                            implementation,
                        ).build(),
                ).build(),
        )
    }

    /** The evaluated display of the presented resource; only resource scopes have one. */
    private val appearanceType = Api.Expr.parameterizedBy(Api.ResourceAppearance, Api.Handled)

    private fun appearance(): PropertySpec =
        PropertySpec
            .builder("appearance", appearanceType)
            .addKdoc("The label, accent and icon of the presented resource, as its most specific display declares them.")
            .build()

    private fun FieldShape.presentedField(): TypeName = Api.PresentedField.parameterizedBy(native, presentationControl)
}

/** The presented value of a declaration whose fields do not cover it: abstract types and nominal scalars. */
private class RootPresentation(
    val shape: FieldShape,
    val fieldType: TypeName,
)

private fun SdkDeclaration.rootPresentation(): RootPresentation? {
    if (!abstract && definition.representation is RepresentationTemplate.Record) return null
    val shape =
        when (val own = shape) {
            is FieldShape.Record -> own.copy(native = starType, arguments = emptyList())
            is FieldShape.Enumeration -> own.copy(native = starType)
            else -> own
        }
    return RootPresentation(shape, Api.PresentedField.parameterizedBy(selfType, shape.presentationControl))
}
