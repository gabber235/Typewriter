package com.typewritermc.formula.codegen

import com.google.devtools.ksp.getClassDeclarationByName
import com.google.devtools.ksp.isConstructor
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeReference
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ANY
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LambdaTypeName
import com.squareup.kotlinpoet.ParameterizedTypeName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.squareup.kotlinpoet.WildcardTypeName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.squareup.kotlinpoet.ksp.toTypeParameterResolver
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.declarationCode
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.listCode
import com.typewritermc.codegen.setCode
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.formula.TypewriterFormulaName
import com.typewritermc.formula.TypewriterFormulaProvider
import com.typewritermc.types.catalog.referencedDefinitions
import com.typewritermc.types.codegen.DefinitionOwners
import com.typewritermc.types.codegen.SdkNames
import com.typewritermc.types.ksp.KspSignatureConversion
import com.typewritermc.types.ksp.KspTypeGraphConverter
import com.typewritermc.types.parts
import com.typewritermc.types.qualified
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Emits one `GeneratedFormulaProvider` for each `@TypewriterFormulaProvider` object, listing a `FormulaFunction` for
 * each of its visible functions and properties.
 *
 * A signature is written in the catalog's type forms: a receiver is the first context slot, named `this`, then come
 * the parameters and the result. A function's type parameters are owned by the synthetic id
 * `qualified("formula", "<object>.<function>")`, with `#<n>` added when the object declares that Kotlin name more than
 * once. The generated invoke converts each argument with `intoKotlin` at its declared template and the result with
 * `fromKotlin`, so generated code is the one place a provider's values become Kotlin. A call leaves out a defaulted
 * parameter by passing `NotProvided`; the invoke has one Kotlin call per subset of left out parameters, since a call
 * site cannot name a Kotlin default any other way, which is why at most four parameters may have a default.
 *
 * Context parameters are not supported yet: KSP does not report them, so a provider function that declares one gets
 * a generated call without it, which does not compile. Reading them is added when KSP reports them.
 */
internal class FormulaProviderProcessor(
    private val output: GeneratedOutput,
    private val owners: DefinitionOwners,
    private val logger: KSPLogger,
    /** Whether this compilation generates the definition of a declaration that has no `@TypewriterType`. */
    private val imported: (KSClassDeclaration) -> Boolean,
) {
    /** Processes this round's formula providers and returns the symbols to defer. */
    fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterFormulaProvider::class).toList()
        context(resolver) { symbols.filter(KSAnnotated::validate).forEach { provide(it) } }
        return symbols.filterNot(KSAnnotated::validate)
    }

    context(_: Resolver)
    private fun provide(symbol: KSAnnotated) {
        val owner = symbol as? KSClassDeclaration
        if (owner == null || owner.classKind != ClassKind.OBJECT) {
            logger.error("A formula provider must be an object.", symbol)
            return
        }
        if (owner.qualifiedName == null || Modifier.PRIVATE in owner.modifiers) {
            logger.error("A formula provider must be visible.", owner)
            return
        }
        val members =
            owner.declarations
                .filter { (it is KSFunctionDeclaration && !it.isConstructor()) || it is KSPropertyDeclaration }
                .filterNot { Modifier.PRIVATE in it.modifiers || Modifier.PROTECTED in it.modifiers }
                .toList()
        val sameName = members.groupingBy { it.simpleName.asString() }.eachCount()
        val ordinals = mutableMapOf<String, Int>()
        val functions =
            members.mapIndexed { index, member ->
                val kotlinName = member.simpleName.asString()
                val ordinal = ordinals.merge(kotlinName, 1, Int::plus)!! - 1
                val suffix = if (sameName.getValue(kotlinName) > 1) "#$ordinal" else ""
                val typeOwner = TypeDefinitionId.qualified("formula", "${owner.qualifiedName!!.asString()}.$kotlinName$suffix")
                member(owner, member, index, typeOwner)
            }
        if (functions.any { it == null }) return
        val providerClass =
            ClassName(owner.packageName.asString(), "${owner.toClassName().simpleNames.joinToString("")}GeneratedFormulaProvider")
        val type =
            TypeSpec
                .classBuilder(providerClass)
                .addSuperinterface(Api.GeneratedFormulaProvider)
                .apply { functions.filterNotNull().forEach { function -> function.properties.forEach(::addProperty) } }
                .addProperty(
                    PropertySpec
                        .builder("functions", List::class.asClassName().parameterizedBy(Api.FormulaFunction), KModifier.OVERRIDE)
                        .initializer(functions.filterNotNull().map(FormulaMember::function).listCode())
                        .build(),
                ).build()
        output.provide(
            GeneratedFile.builder(providerClass.packageName, providerClass.simpleName).addType(type).build(),
            providerClass,
            GeneratedProviderKind.Formula,
            owner,
        )
    }

    /** The generated function of one provider [declaration], or null after reporting why it cannot be one. */
    context(_: Resolver)
    private fun member(
        owner: KSClassDeclaration,
        declaration: KSDeclaration,
        index: Int,
        typeOwner: TypeDefinitionId,
    ): FormulaMember? {
        val member = ProviderMember(declaration)
        val problems = member.shapeProblems().toMutableList()
        val conversion =
            KspTypeGraphConverter().convertSignature(declaration, typeOwner, member.positions) { diagnostics ->
                problems += diagnostics.map { it.toString() }
            }
        conversion?.let { problems += catalogProblems(it) }
        problems.forEach { logger.error(it, declaration) }
        if (problems.isNotEmpty() || conversion == null) return null
        val signature = member.signature(conversion)
        val referenced =
            (signature.parts + conversion.typeParameters.flatMap { it.bounds }).flatMapTo(linkedSetOf()) { it.referencedDefinitions() } - typeOwner
        val ownerName = "owner$index"
        val references =
            owners
                .references(
                    conversion.declarations,
                    referenced,
                    declaration,
                )?.withLocal(mapOf(typeOwner to CodeBlock.of("%N", ownerName)))
                ?: return null
        val invocation = FormulaInvocation(owner, declaration, member.receiver, "signature$index", conversion)
        return context(references) {
            FormulaMember(
                properties =
                    listOfNotNull(
                        PropertySpec
                            .builder(ownerName, TypeDefinitionId::class, KModifier.PRIVATE)
                            .initializer(typeOwner.declarationCode())
                            .build()
                            .takeIf { conversion.typeParameters.isNotEmpty() },
                        PropertySpec
                            .builder("signature$index", FunctionTypeTemplate::class, KModifier.PRIVATE)
                            .initializer(signature.code())
                            .build(),
                    ),
                function = member.functionCode(conversion, "signature$index", invocation),
            )
        }
    }

    /** Each type the signature reaches that has no catalog definition, which formulas could not name. */
    context(resolver: Resolver)
    private fun catalogProblems(conversion: KspSignatureConversion): List<String> =
        conversion.declarations.mapNotNull { (id, declaration) ->
            val generated = resolver.getClassDeclarationByName(SdkNames.of(declaration).definition.canonicalName) != null
            "${declaration.simpleName.asString()} has no catalog type.".takeIf { id.isPlainKotlin && !imported(declaration) && !generated }
        }
}

/** One function or property of a formula provider, read as a formula signature. */
private class ProviderMember(
    private val declaration: KSDeclaration,
) {
    private val function = declaration as? KSFunctionDeclaration
    private val property = declaration as? KSPropertyDeclaration
    private val kotlinName = declaration.simpleName.asString()
    val receiver: KSTypeReference? = function?.extensionReceiver ?: property?.extensionReceiver
    private val parameters = function?.parameters.orEmpty()
    private val result: KSTypeReference = function?.returnType ?: requireNotNull(property).type

    /** The receiver, then the parameters, then the result. */
    val positions: List<KSTypeReference> = listOfNotNull(receiver) + parameters.map { it.type } + result

    /** What the Kotlin shape of this member breaks, before its types are converted. */
    fun shapeProblems(): List<String> {
        val receiverDeclaration = receiver?.resolve()?.declaration as? KSClassDeclaration
        return listOfNotNull(
            "A formula provider function cannot suspend.".takeIf { function != null && Modifier.SUSPEND in function.modifiers },
            "A formula provider function cannot take a vararg.".takeIf { parameters.any { it.isVararg } },
            "A member of ${receiverDeclaration?.simpleName?.asString()} hides $kotlinName. Give it another Kotlin name and @TypewriterFormulaName."
                .takeIf { receiverDeclaration?.hasMember(kotlinName) == true },
            "A formula provider function can default at most four parameters.".takeIf {
                parameters.count { it.hasDefault } > MAX_DEFAULTED
            },
            "A function parameter can have at most three parameters.".takeIf { positions.any { it.resolve().hasWideFunction() } },
        )
    }

    /** The signature in catalog forms: the receiver as the context slot `this`, then the parameters, then the result. */
    fun signature(conversion: KspSignatureConversion): FunctionTypeTemplate {
        val offset = if (receiver == null) 0 else 1
        return FunctionTypeTemplate(
            context = listOfNotNull(receiver).map { FunctionParameterTemplate(name = RECEIVER, type = conversion.positions.first()) },
            parameters =
                parameters.mapIndexed { position, parameter ->
                    FunctionParameterTemplate(name = parameter.name!!.asString(), type = conversion.positions[position + offset])
                },
            result = conversion.positions.last(),
        )
    }

    /** The `FormulaFunction` expression, reading its signature from the property [signature]. */
    context(_: DefinitionReferences)
    fun functionCode(
        conversion: KspSignatureConversion,
        signature: String,
        invocation: FormulaInvocation,
    ): CodeBlock =
        CodeBlock
            .builder()
            .add("%T(\n⇥", Api.FormulaFunction)
            .add("name = %S,\n", declaration.annotation<TypewriterFormulaName>()?.name ?: kotlinName)
            .add("typeParameters = %L,\n", conversion.typeParameters.map { it.kotlinCode() }.listCode())
            .add("signature = %N,\n", signature)
            .add("defaulted = %L,\n", parameters.filter { it.hasDefault }.map { CodeBlock.of("%S", it.name!!.asString()) }.setCode())
            .add("⇤) { arguments ->\n⇥%L⇤}", invocation.body())
            .build()
}

/** The generated parts of one formula function: the properties it reads and the `FormulaFunction` expression. */
private class FormulaMember(
    val properties: List<PropertySpec>,
    val function: CodeBlock,
)

/** The body of a generated invoke: convert each argument, call the Kotlin member once per subset of defaults, convert the result. */
private class FormulaInvocation(
    private val owner: KSClassDeclaration,
    private val member: KSDeclaration,
    private val receiver: KSTypeReference?,
    private val signature: String,
    conversion: KspSignatureConversion,
) {
    private val parameters = (member as? KSFunctionDeclaration)?.parameters.orEmpty()
    private val typeNames = member.typeParameters.toTypeParameterResolver()
    private val erased: Map<String, TypeName> =
        member.typeParameters.associate { parameter ->
            val bound = parameter.bounds.firstOrNull()?.toTypeName(typeNames)
            parameter.name.asString() to (bound?.erase(emptyMap()) ?: ANY.copy(nullable = true))
        }

    init {
        check(conversion.positions.size == listOfNotNull(receiver).size + parameters.size + 1)
    }

    fun body(): CodeBlock {
        val builder = CodeBlock.builder()
        var argument = 0
        if (receiver != null) {
            builder.add("val v0 = intoKotlin(arguments[0], %N.context[0].type)·as·%T\n", signature, receiver.castName())
            argument = 1
        }
        val values =
            parameters.mapIndexed { position, parameter ->
                val index = argument + position
                val name = "v$index"
                if (parameter.hasDefault) {
                    builder.add("val p$index = arguments[$index]·!==·%T\n", Api.NotProvided)
                    builder.add(
                        "val $name = if (p$index) intoKotlin(arguments[$index], %N.parameters[$position].type) else null\n",
                        signature,
                    )
                } else {
                    builder.add(
                        "val $name = intoKotlin(arguments[$index], %N.parameters[$position].type)·as·%T\n",
                        signature,
                        parameter.type.castName(),
                    )
                }
                Argument(parameter.name!!.asString(), index, parameter.hasDefault, parameter.type.castName())
            }
        val defaulted = values.filter(Argument::defaulted)
        val call =
            if (defaulted.isEmpty()) {
                call(values)
            } else {
                val branches = CodeBlock.builder().add("when {\n⇥")
                ((1 shl defaulted.size) - 1 downTo 0).forEach { mask ->
                    val given = defaulted.filterIndexed { bit, _ -> mask and (1 shl bit) != 0 }.toSet()
                    val condition =
                        if (mask == 0) {
                            CodeBlock.of("else")
                        } else {
                            defaulted
                                .map {
                                    if (it in
                                        given
                                    ) {
                                        CodeBlock.of("p${it.index}")
                                    } else {
                                        CodeBlock.of("!p${it.index}")
                                    }
                                }.joinToCode(" && ")
                        }
                    branches.add("%L -> %L\n", condition, call(values.filter { !it.defaulted || it in given }))
                }
                branches.add("⇤}").build()
            }
        builder.add("val result = with(%T) {\n⇥%L\n⇤}\n", owner.toClassName(), call)
        builder.add("fromKotlin(result, %N.result)\n", signature)
        return builder.build()
    }

    private fun call(arguments: List<Argument>): CodeBlock {
        val target =
            if (receiver !=
                null
            ) {
                CodeBlock.of("v0.%N", member.simpleName.asString())
            } else {
                CodeBlock.of("%N", member.simpleName.asString())
            }
        if (member is KSPropertyDeclaration) return target
        val passed =
            arguments.map { argument ->
                if (argument.defaulted) {
                    CodeBlock.of("%N = v${argument.index}·as·%T", argument.name, argument.type)
                } else {
                    CodeBlock.of("%N = v${argument.index}", argument.name)
                }
            }
        // A type parameter may appear only in the result, so the call names each one's erased form.
        val typeArguments =
            if (erased.isEmpty()) CodeBlock.of("") else CodeBlock.of("<%L>", erased.values.map { CodeBlock.of("%T", it) }.joinToCode(", "))
        return CodeBlock.of("%L%L(%L)", target, typeArguments, passed.joinToCode(", "))
    }

    /** The Kotlin type a converted value is cast to: the declared type with each of the member's type parameters erased to its bound. */
    private fun KSTypeReference.castName(): TypeName = toTypeName(typeNames).erase(erased)

    private class Argument(
        val name: String,
        val index: Int,
        val defaulted: Boolean,
        val type: TypeName,
    )
}

context(_: DefinitionReferences)
private fun FunctionTypeTemplate.code(): CodeBlock {
    fun slots(slots: List<FunctionParameterTemplate>) =
        slots.map { CodeBlock.of("%T(name·=·%S,♢type·=·%L)", FunctionParameterTemplate::class, it.name, it.type.kotlinCode()) }.listCode()
    return CodeBlock.of(
        "%T(\n⇥context·=·%L,\nparameters·=·%L,\nresult·=·%L,\n⇤)",
        FunctionTypeTemplate::class,
        slots(context),
        slots(parameters),
        result.kotlinCode(),
    )
}

/** This type with each named type variable replaced; a variable not in [variables] becomes `Any?`. */
private fun TypeName.erase(variables: Map<String, TypeName>): TypeName =
    when (this) {
        is TypeVariableName -> {
            val replacement = variables[name] ?: ANY.copy(nullable = true)
            if (isNullable) replacement.copy(nullable = true) else replacement
        }

        is ParameterizedTypeName -> {
            rawType.parameterizedBy(typeArguments.map { it.erase(variables) }).copy(nullable = isNullable)
        }

        is LambdaTypeName -> {
            LambdaTypeName
                .get(
                    receiver = receiver?.erase(variables),
                    parameters = parameters.map { it.toBuilder(type = it.type.erase(variables)).build() },
                    returnType = returnType.erase(variables),
                ).copy(nullable = isNullable)
        }

        is WildcardTypeName -> {
            when {
                inTypes.isNotEmpty() -> WildcardTypeName.consumerOf(inTypes.single().erase(variables))
                else -> WildcardTypeName.producerOf(outTypes.single().erase(variables))
            }
        }

        else -> {
            this
        }
    }

/** Whether a Kotlin member of this class has [name], so an extension of that name would never be called. */
private fun KSClassDeclaration.hasMember(name: String): Boolean =
    getAllFunctions().any { it.simpleName.asString() == name } || getAllProperties().any { it.simpleName.asString() == name }

/** Whether this type, or a type inside it, is a function type with more parameters than a formula lambda can have. */
private fun KSType.hasWideFunction(): Boolean =
    (isFunctionType && arguments.size - 1 > MAX_FUNCTION_PARAMETERS) || arguments.any { it.type?.resolve()?.hasWideFunction() == true }

/** Whether this id is a Kotlin class's qualified name, which a declaration without `@TypewriterType` gets. */
private val TypeDefinitionId.isPlainKotlin: Boolean
    get() = (typeId as? TypeId.QualifiedWrapper)?.value?.namespace == "kotlin"

private const val RECEIVER = "this"
private const val MAX_DEFAULTED = 4
private const val MAX_FUNCTION_PARAMETERS = 3
