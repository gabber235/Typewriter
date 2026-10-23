package com.typewritermc.expression.operations

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.append
import skirout.editor.v1.expression.FailureId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import java.math.BigDecimal
import java.math.BigInteger

/**
 * A declared failure raised by a kernel or the call rule. [failure] is a generated constant of [KernelFailure] or
 * [EvaluatorFailure]; evaluation turns it into a failed result. Anything else a kernel throws is a bug and propagates.
 */
class OperationFailure(
    val failure: FailureId,
    message: String = failure.value,
) : RuntimeException(message)

/** A number of one family, as numeric kernels receive and return it. */
sealed interface PortableNumber {
    data class Integer(
        val value: BigInteger,
    ) : PortableNumber

    /** Always finite. */
    data class Float(
        val value: Double,
    ) : PortableNumber

    data class Decimal(
        val value: BigDecimal,
    ) : PortableNumber
}

/** A kernel result that may be missing data at the locations that block it. */
sealed interface PortableMaybe<out T> {
    data class Value<out T>(
        val value: T,
    ) : PortableMaybe<T>

    data class Missing(
        val locations: List<ValueLocation>,
    ) : PortableMaybe<Nothing>
}

/** A value together with the authored location it was read from, when it has one. */
data class Located<out T>(
    val value: T,
    val location: ValueLocation?,
) {
    /** The location of the collection item [id] below this value. */
    fun item(id: ItemId): ValueLocation? = location?.append(ValuePath(segments = listOf(PathSegment.createItem(id = id))))

    /** The location of the key of map row [id] below this value. */
    fun mapKey(id: ItemId): ValueLocation? =
        location?.append(ValuePath(segments = listOf(PathSegment.createItem(id = id), PathSegment.MAP_KEY)))

    /** The location of the value of map row [id] below this value. */
    fun mapValue(id: ItemId): ValueLocation? =
        location?.append(ValuePath(segments = listOf(PathSegment.createItem(id = id), PathSegment.MAP_VALUE)))
}

/** A step lambda the kernel drives with the accumulator and one source item. */
fun interface PortableStep {
    fun invoke(
        accumulator: DataValue,
        item: ListItem,
    ): DataValue
}

/** A comparator lambda the kernel drives with two source items; negative, zero or positive. */
fun interface PortableComparator {
    fun compare(
        left: ListItem,
        right: ListItem,
    ): Int
}

/** A lambda the kernel runs once with one value. */
fun interface PortableApply {
    fun invoke(value: DataValue): DataValue
}

/** The evaluation budget for work that grows with an operation's input. Exhaustion raises a declared failure. */
interface PortableMeter {
    fun steps(count: Int)

    fun items(count: Int)
}

/** The catalog's type facts that typed operations need at evaluation time. */
interface PortableTypes {
    /** Whether [value]'s actual type is [type] or one of its descendants. */
    fun isInstance(
        value: DataValue,
        type: TypeUse,
    ): Boolean

    /** The case names of the enumeration [type], in declaration order. */
    fun enumCases(type: TypeUse): List<String>

    /** Whether the catalog admits [value] as a value of [type]. */
    fun admits(
        value: DataValue,
        type: TypeUse,
    ): Boolean
}

/** One argument as the call rule hands it to a generated invoker. */
sealed interface KernelArgument {
    /** An evaluated argument and the authored location it projects, when it has one. */
    data class Value(
        val value: DataValue,
        val location: ValueLocation?,
    ) : KernelArgument

    /** The results of an each lambda, one per item of the first argument, in item order. */
    data class Each(
        val results: List<DataValue>,
    ) : KernelArgument

    /**
     * A lambda the kernel drives. [invoke] binds one local per input; an input with an [ItemId] is an item of the
     * first argument, so the local keeps that item's location. Missing or failed bodies abort the whole call.
     */
    class Lambda(
        val invoke: (List<LocalInput>) -> DataValue,
    ) : KernelArgument

    data class LocalInput(
        val value: DataValue,
        val item: ItemId? = null,
    )
}

/** The capabilities a kernel may use besides its arguments, supplied by the evaluating host. */
class KernelContext(
    val meter: PortableMeter,
    private val typeFacts: PortableTypes?,
) {
    /** The catalog type facts; operations that use them fail on a host that has none. */
    val types: PortableTypes
        get() = typeFacts ?: throw OperationFailure(EvaluatorFailure.OutsideRuleProfile, "This host has no catalog type facts.")
}

/**
 * Runs one declared operation with converted arguments; generated per operation in the rule kernel dispatch.
 * [typeArguments] are the call's closed type arguments, one per explicit type parameter.
 */
class OperationInvoker(
    val operation: PortableOperation,
    private val run: (arguments: List<KernelArgument>, typeArguments: List<TypeUse>, context: KernelContext) -> Availability<DataValue>,
) {
    fun invoke(
        arguments: List<KernelArgument>,
        typeArguments: List<TypeUse>,
        context: KernelContext,
    ): Availability<DataValue> = run(arguments, typeArguments, context)
}

/** Thrown out of a kernel driven lambda whose body is missing or failed, so the call returns that result. */
class LambdaInterrupted(
    val result: Availability<DataValue>,
) : RuntimeException(null, null, false, false)
