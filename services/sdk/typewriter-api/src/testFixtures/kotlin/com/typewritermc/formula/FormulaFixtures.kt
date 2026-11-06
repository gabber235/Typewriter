package com.typewritermc.formula

import com.typewritermc.authoring.complete
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.testkit.complete
import com.typewritermc.testkit.generatedProviders
import com.typewritermc.testkit.generatedTypeCatalog
import com.typewritermc.testkit.ready
import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.floatScalar
import com.typewritermc.types.functionUse
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

/** The standard types plus every type typewriter-api declares, Formula and Var among them. */
val formulaCatalog: DefaultCheckedCatalog by lazy { generatedTypeCatalog("formula test") }

/** The native bindings of every type typewriter-api declares, over [formulaCatalog]. */
val formulaBindings: FactoryNativeBindingRegistry by lazy {
    FactoryNativeBindingRegistry(
        formulaCatalog,
        generatedProviders<NativeBindingFactory>(GeneratedProviderKind.NativeBinding).distinctBy(NativeBindingFactory::provider),
    )
}

/** The Kotlin value the stored [value] of [use] decodes to; fails when the value is not complete. */
@Suppress("UNCHECKED_CAST")
fun <T> decode(
    use: TypeUse,
    value: DataValue,
): T {
    val checked = formulaCatalog.ready(use)
    return formulaBindings.bind(checked).decode(checked.complete(value).complete()) as T
}

/** The stored form of the Kotlin [value] of [use]. */
@Suppress("UNCHECKED_CAST")
fun <T> encode(
    use: TypeUse,
    value: T,
): DataValue = (formulaBindings.bind(formulaCatalog.ready(use)) as NativeBinding<T>).encode(value)

/** A Var of [value] whose formulas read the named [context] slots, as `Var<T, Scope>` lowers in Kotlin. */
fun varOf(
    value: TypeUse,
    context: List<Pair<String, TypeUse>> = emptyList(),
): TypeUse = VarDefinition.id.use(varArguments(value, context))

/** The plain case of [varOf], whose value is stored as itself. */
fun varValue(
    value: TypeUse,
    context: List<Pair<String, TypeUse>> = emptyList(),
): NamedTypeUse = VarDefinition.id.member("Value").namedUse(varArguments(value, context))

/** The formula case of [varOf], whose value is a stored Formula. */
fun varComputed(
    value: TypeUse,
    context: List<Pair<String, TypeUse>> = emptyList(),
): NamedTypeUse = VarDefinition.id.member("Computed").namedUse(varArguments(value, context))

private fun varArguments(
    value: TypeUse,
    context: List<Pair<String, TypeUse>>,
): List<TypeUse> = listOf(value, functionUse(context = context, result = value))

/** The 32 bit signed integer, Kotlin's Int. */
val int: TypeUse = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use

/** The function type taking these named [parameters] and returning [result], with no context. */
fun function(
    vararg parameters: Pair<String, TypeUse>,
    result: TypeUse,
): TypeUse = functionUse(parameters = parameters.toList(), result = result)

/** A list of [item]. */
fun listUse(item: TypeUse): TypeUse = StandardTypes.list.use(listOf(item))

/** Functions returning functions, [depth] levels deep. */
fun nestedFunctions(depth: Int): TypeUse = (1 until depth).fold(int) { inner, _ -> function("x" to int, result = inner) }

/** A stored formula body with [source] and no references. */
fun formulaValue(source: String): DataValue =
    DataValue.named(
        FORMULA_USE,
        DataValue.record(
            "source" to DataValue.StringValueWrapper(source),
            "references" to
                DataValue.named(StandardTypes.list.namedUse(listOf(FormulaReferenceDefinition.id.use())), DataValue.listValue(emptyList())),
        ),
    )

/** Every formula function the generated provider indexes on the test class path list, the standard library among them. */
val formulaFunctions: List<FormulaFunction> by lazy {
    generatedProviders<GeneratedFormulaProvider>(GeneratedProviderKind.Formula).flatMap(GeneratedFormulaProvider::functions)
}

/**
 * Calls the formula function [name] whose context and parameters fit the Kotlin [arguments], as a formula call with
 * those values would. Scalars, lists and Kotlin functions are their own evaluation values, so they pass unchanged.
 */
fun callFormula(
    name: String,
    vararg arguments: Any?,
): Any? {
    val function =
        formulaFunctions.single { function ->
            val slots = function.signature.context + function.signature.parameters
            function.name == name && slots.size == arguments.size && slots.zip(arguments).all { (slot, value) -> value.fits(slot.type) }
        }
    return function.invoke(KotlinValues, arguments.toList())
}

private fun Any?.fits(type: TypeTemplate): Boolean =
    when (this) {
        is Int -> type == integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
        is Long -> type == integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).template
        is Double -> type == floatScalar(FloatWidth.SIXTY_FOUR).template
        is String -> type == ScalarKind.TEXT.template
        is Boolean -> type == ScalarKind.BOOLEAN.template
        is List<*> -> type.named?.definition == StandardTypes.list
        is Function<*> -> type is TypeTemplate.FunctionWrapper
        else -> false
    }

/** A formula call over values that are already their Kotlin form. */
private object KotlinValues : FormulaCall {
    override fun intoKotlin(
        value: Any?,
        type: TypeTemplate,
    ): Any? = value

    override fun fromKotlin(
        value: Any?,
        type: TypeTemplate,
    ): Any? = value

    override fun display(value: Any?): String = value.toString()

    override fun resolve(value: Any?): Any? = value

    override fun force(value: Any?): Any? = value

    override fun fail(message: String): Nothing = throw FormulaFailureException(FormulaFailure.ProviderThrew(message))
}
