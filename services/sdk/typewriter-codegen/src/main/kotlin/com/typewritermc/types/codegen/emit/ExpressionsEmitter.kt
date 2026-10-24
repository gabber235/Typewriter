package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.AnnotationSpec
import com.squareup.kotlinpoet.BOOLEAN
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LIST
import com.squareup.kotlinpoet.LambdaTypeName
import com.squareup.kotlinpoet.NOTHING
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.STRING
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.squareup.kotlinpoet.WildcardTypeName
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.types.codegen.parameterizedOrSelf
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/** `XExpressions`, its implementation and factory, plus the collection helpers that take typed predicates. */
internal object ExpressionsEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        val names = declaration.names
        val variables = declaration.typeVariables
        val receiver =
            generateSequence("receiverExpression") { "_$it" }
                .first { candidate -> declaration.fields.none { it.property == candidate } }
        addType(
            TypeSpec
                .interfaceBuilder(names.expressions)
                .addTypeVariables(variables)
                .addProperties(declaration.fields.map { field -> PropertySpec.builder(field.property, field.expressionType()).build() })
                .build(),
        )
        addType(
            TypeSpec
                .classBuilder(names.expressionsImpl)
                .addModifiers(KModifier.INTERNAL)
                .addTypeVariables(variables)
                .primaryConstructor(FunSpec.constructorBuilder().addParameter(receiver, ANY_EXPRESSION).build())
                .addProperty(PropertySpec.builder(receiver, ANY_EXPRESSION, KModifier.PRIVATE).initializer(receiver).build())
                .addSuperinterface(declaration.expressionsType)
                .addProperties(
                    declaration.fields.map { field ->
                        PropertySpec
                            .builder(field.property, field.expressionType(), KModifier.OVERRIDE)
                            .getter(
                                FunSpec.getterBuilder().addStatement("return %N.%M(%S)", receiver, Api.expressionField, field.name).build(),
                            ).build()
                    },
                ).build(),
        )
        val starExpressions = names.expressions.parameterizedOrSelf(variables.map { STAR })
        addType(
            TypeSpec
                .objectBuilder(names.expressionsFactory)
                .addSuperinterface(Api.ExpressionFactory.parameterizedBy(starExpressions))
                .addProperty(
                    PropertySpec
                        .builder("scope", KClass::class.asClassName().parameterizedBy(starExpressions), KModifier.OVERRIDE)
                        .initializer("%T::class as %T", names.expressions, KClass::class.asClassName().parameterizedBy(starExpressions))
                        .build(),
                ).addFunction(
                    FunSpec
                        .builder("create")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("value", ANY_EXPRESSION)
                        .returns(starExpressions)
                        .addStatement("return %T(value)", names.expressionsImpl.parameterizedOrSelf(variables.map { NOTHING }))
                        .build(),
                ).build(),
        )
        if (declaration.resource) addProperty(declaration.resourceFields())
        if (!declaration.generic && (declaration.definition.representation as? RepresentationTemplate.Scalar)?.kind == ScalarKind.Text) {
            addProperty(declaration.textRepresentation())
        }
        addFunction(declaration.collectionHelper("any", Api.collectionAny, BOOLEAN))
        addFunction(declaration.collectionHelper("filter", Api.collectionFilter, LIST.parameterizedBy(declaration.selfType)))
    }

    private fun com.typewritermc.types.codegen.SdkField.expressionType(): TypeName =
        Api.Expr.parameterizedBy(shape.native, Api.MayBeMissing)

    /** `resource.fields` on a typed resource expression. */
    private fun SdkDeclaration.resourceFields(): PropertySpec =
        PropertySpec
            .builder("fields", expressionsType)
            .addAnnotation(jvmName("${names.baseName}ResourceFields", getter = true))
            .addTypeVariables(typeVariables)
            .receiver(Api.ResourceExpr.parameterizedBy(selfType))
            .getter(
                FunSpec
                    .getterBuilder()
                    .addStatement("return %T.create(value) as %T", names.expressionsFactory, expressionsType)
                    .build(),
            ).build()

    /** `.text` on expressions of a text backed nominal type. */
    private fun SdkDeclaration.textRepresentation(): PropertySpec {
        val missing = TypeVariableName("M", Api.MissingPolicy)
        return PropertySpec
            .builder("text", Api.Expr.parameterizedBy(STRING, missing))
            .addAnnotation(jvmName("${names.baseName}TextRepresentation", getter = true))
            .addTypeVariable(missing)
            .receiver(Api.Expr.parameterizedBy(selfType, missing))
            .getter(FunSpec.getterBuilder().addStatement("return %M(this)", Api.textRepresentation).build())
            .build()
    }

    /** `any` and `filter` over a list of this declaration with a predicate written against its expressions. */
    private fun SdkDeclaration.collectionHelper(
        name: String,
        implementation: com.squareup.kotlinpoet.MemberName,
        result: TypeName,
    ): FunSpec {
        val missing = TypeVariableName("M", Api.MissingPolicy)
        val predicate = LambdaTypeName.get(receiver = expressionsType, returnType = Api.Expr.parameterizedBy(BOOLEAN, OUT_MISSING))
        return FunSpec
            .builder(name)
            .addAnnotation(jvmName("${names.baseName}Expression${name.replaceFirstChar(Char::uppercaseChar)}"))
            .addTypeVariables(typeVariables + missing)
            .receiver(Api.Expr.parameterizedBy(LIST.parameterizedBy(selfType), missing))
            .addParameter("predicate", predicate)
            .returns(Api.Expr.parameterizedBy(result, Api.MayBeMissing))
            .addStatement(
                "return %M(this,♢%T as %T,♢predicate)",
                implementation,
                names.expressionsFactory,
                Api.ExpressionFactory.parameterizedBy(expressionsType),
            ).build()
    }
}

internal val OUT_MISSING: TypeName = WildcardTypeName.producerOf(Api.MissingPolicy)

/** `Expr<*, out MissingPolicy>`: any expression, the input of generated expression scopes. */
internal val ANY_EXPRESSION: TypeName = Api.Expr.parameterizedBy(STAR, OUT_MISSING)

internal fun jvmName(
    name: String,
    getter: Boolean = false,
): AnnotationSpec =
    AnnotationSpec
        .builder(JvmName::class)
        .addMember("%S", name)
        .apply { if (getter) useSiteTarget(AnnotationSpec.UseSiteTarget.GET) }
        .build()
