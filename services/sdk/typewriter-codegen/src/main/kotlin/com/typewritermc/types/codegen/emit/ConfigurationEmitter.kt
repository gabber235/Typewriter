package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.AnnotationSpec
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.types.codegen.FieldShape
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.SdkField
import com.typewritermc.types.codegen.configurationScope
import com.typewritermc.types.codegen.configurationScopeCreation
import com.typewritermc.types.codegen.expressionFactory
import com.typewritermc.types.codegen.kotlinCode
import com.typewritermc.types.codegen.parameterizedOrSelf
import com.typewritermc.types.codegen.rawClass
import com.typewritermc.types.codegen.representationKind
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeTemplate
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/** `XConfiguration`, its scope and the scope implementation that collects rules for each field. */
internal object ConfigurationEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        val names = declaration.names
        val variables = declaration.typeVariables
        val scope = names.configurationScope.parameterizedOrSelf(variables)
        val root = declaration.rootConfiguration()
        addType(
            TypeSpec
                .interfaceBuilder(names.configuration)
                .addAnnotation(generatedContract(GeneratedContract.Kind.Configuration, declaration))
                .addTypeVariables(variables)
                .addFunction(
                    FunSpec
                        .builder("configure")
                        .addModifiers(KModifier.ABSTRACT)
                        .receiver(scope)
                        .build(),
                ).build(),
        )
        addType(
            TypeSpec
                .interfaceBuilder(names.configurationScope)
                .addTypeVariables(variables)
                .addSuperinterface(root.scope)
                .addFunctions(declaration.fields.map { field -> field.configureFunction(KModifier.ABSTRACT) })
                .build(),
        )
        addType(
            TypeSpec
                .classBuilder(names.configurationScopeImpl)
                .addTypeVariables(variables)
                .primaryConstructor(FunSpec.constructorBuilder().addParameter("collection", Api.ConfigurationCollectionScope).build())
                .addProperty(
                    PropertySpec
                        .builder(
                            "collection",
                            Api.ConfigurationCollectionScope,
                            KModifier.PRIVATE,
                        ).initializer("collection")
                        .build(),
                )
                // The delegated supertype comes first: a `where` clause directly after a delegation expression parses as
                // an infix call.
                .addSuperinterface(root.scope, context(declaration.references) { root.delegate() })
                .addSuperinterface(scope)
                .addFunctions(
                    declaration.fields.map { field ->
                        val pattern = RelativeFieldPattern(listOf(FieldPatternSegment.Field(field.name)))
                        field
                            .configureFunction(KModifier.OVERRIDE)
                            .toBuilder()
                            .addStatement(
                                "%L.configure()",
                                context(declaration.references) { field.shape.configurationScopeCreation("collection", pattern) },
                            ).build()
                    },
                ).build(),
        )
    }

    private fun SdkField.configureFunction(modifier: KModifier): FunSpec =
        FunSpec
            .builder(property)
            .addModifiers(modifier)
            .addParameter("configure", Api.Configuration.parameterizedBy(shape.configurationScope))
            .build()
}

/** The configuration of a declaration's own value, which its scope implementation delegates to. */
private class RootConfiguration(
    val scope: TypeName,
    val kind: RepresentationKind,
    val expected: TypeTemplate,
    val expressions: com.squareup.kotlinpoet.ClassName,
) {
    context(_: com.typewritermc.codegen.DefinitionReferences)
    fun delegate(): CodeBlock =
        CodeBlock.of(
            "collection.field(\n⇥%L,\n%T.%L,\n%L,\n%T::class as %T,\nemptyMap(),\n%T,\n⇤)",
            RelativeFieldPattern().kotlinCode(),
            RepresentationKind::class,
            kind.name,
            expected.kotlinCode(),
            scope.rawClass,
            KClass::class.asClassName().parameterizedBy(scope),
            expressions,
        )
}

private fun SdkDeclaration.rootConfiguration(): RootConfiguration =
    when (val representation = definition.representation) {
        is RepresentationTemplate.ScalarWrapper -> {
            val shape =
                when (val own = shape) {
                    is FieldShape.Color, is FieldShape.Wrapped -> own
                    else -> FieldShape.Scalar(representation.value.kind, representation.value.kind.template, selfType)
                }
            RootConfiguration(
                scope = shape.configurationScope,
                kind = representation.value.kind.representationKind,
                expected = representation.value.kind.template,
                expressions = shape.expressionFactory,
            )
        }

        is RepresentationTemplate.EnumerationWrapper -> {
            RootConfiguration(
                scope = Api.EnumField.parameterizedBy(starType),
                kind = RepresentationKind.Enum,
                expected = template.template,
                expressions = Api.EnumExpressions.factory(),
            )
        }

        else -> {
            RootConfiguration(
                scope = Api.RecordField.parameterizedBy(starType, names.expressions.parameterizedOrSelf(typeVariables.map { STAR })),
                kind = RepresentationKind.Record,
                expected = template.template,
                expressions = names.expressionsFactory,
            )
        }
    }

private fun com.squareup.kotlinpoet.ClassName.factory() = peerClass(simpleName + "Factory")

/** `@GeneratedContract(kind, Target::class)`, which marks a generated interface for provider adapter discovery. */
internal fun generatedContract(
    kind: GeneratedContract.Kind,
    declaration: SdkDeclaration,
): AnnotationSpec =
    AnnotationSpec
        .builder(GeneratedContract::class)
        .addMember("kind = %T.%L", GeneratedContract.Kind::class, kind.name)
        .addMember("target = %T::class", declaration.names.source)
        .build()
