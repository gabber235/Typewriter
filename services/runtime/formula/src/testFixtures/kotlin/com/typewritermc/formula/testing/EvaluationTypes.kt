package com.typewritermc.formula.testing

import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Formula
import com.typewritermc.formula.TypewriterFormulaName
import com.typewritermc.formula.TypewriterFormulaProvider
import com.typewritermc.formula.Var
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

// The interpreter's code world: Kotlin records with generated bindings, and providers whose generated invocations the
// interpreter runs, so a test sees what a real extension would get.

@TypewriterType(id = "f0000000000000000000000000000001")
data class Gold(
    val amount: Int,
)

@TypewriterType(id = "f0000000000000000000000000000002")
data class Box<T>(
    val x: T,
)

/** A record with a constructor default and an init check. */
@TypewriterType(id = "f0000000000000000000000000000003")
data class Reward(
    val gold: Int,
    val chest: Boolean = false,
) {
    init {
        require(gold >= 0) { "A reward cannot take gold." }
    }
}

/** Five defaulted fields, so a constructor may leave out any number of them. */
@TypewriterType(id = "f0000000000000000000000000000004")
data class Settings(
    val first: Int = 1,
    val second: Int = 2,
    val third: Int = 3,
    val fourth: Int = 4,
    val fifth: Int = 5,
)

@TypewriterType(id = "f0000000000000000000000000000005")
enum class Season { SPRING, WINTER }

@JvmInline
@TypewriterType(id = "f0000000000000000000000000000006")
value class Coins(
    val amount: Int,
)

@TypewriterType(id = "f0000000000000000000000000000007")
sealed interface Door {
    data object Open : Door

    data object Closed : Door
}

@TypewriterType(id = "f0000000000000000000000000000008")
sealed interface Payment {
    data class Money(
        val amount: Int,
    ) : Payment

    data object Free : Payment
}

/** A record holding a Var, which a formula reads as its value and a provider gets as a Var.Value. */
@TypewriterType(id = "f0000000000000000000000000000009")
data class Mood(
    val level: Var<Int, DefinitionScope>,
)

/** A record holding references. */
@TypewriterType(id = "f000000000000000000000000000000a")
data class Crew(
    val members: List<Ref<ContentReferences.Source, Smith>>,
)

@TypewriterType(id = "f000000000000000000000000000000b")
data class Measure(
    val ratio: Float,
)

/** A resource with a name, which references point at. */
@TypewriterType(id = "f000000000000000000000000000000c")
data class Smith(
    val name: String,
    val mood: Var<Int, DefinitionScope>,
) : Resource

/** A union whose other case holds a Var. */
@TypewriterType(id = "f000000000000000000000000000000d")
sealed interface Signal {
    data object Quiet : Signal

    data class Tuned(
        val level: Var<Int, DefinitionScope>,
    ) : Signal
}

/** Providers the interpreter tests call, each stating what a provider receives or returns. */
@TypewriterFormulaProvider
object EvaluationFormulas {
    @TypewriterFormulaName("get")
    fun <T> Box<T>.content(): T = x

    fun <T> wrap(x: T): Box<T> = Box(x)

    fun explode(): Int = throw IllegalStateException("The provider broke.")

    /** Whether the season is winter; fails unless it got the Kotlin constant. */
    fun Season.isCold(): Boolean = this == Season.WINTER

    /** The id of the resource a Ref names; fails unless it got a Ref. */
    fun Ref<ContentReferences.Source, Smith>.targetId(): String = target.value

    /** Calls [transform] on each reference, failing unless each one is a Ref. */
    fun List<Ref<ContentReferences.Source, Smith>>.eachRef(transform: (Ref<ContentReferences.Source, Smith>) -> String): List<String> =
        map { reference ->
            check(reference is Ref<*, *>) { "Not a Ref: $reference" }
            transform(reference)
        }

    /** The gold of every reward; fails unless each one is a Kotlin Reward. */
    fun List<Reward>.totalGold(): Int = sumOf { it.gold }

    /** The Kotlin class names of the values a generic provider gets. */
    fun <T> List<T>.kinds(): List<String> = map { it?.let { value -> value::class.simpleName }.orEmpty() }

    /** The level a Mood holds; fails unless the Var arrived as a Var.Value. */
    fun Mood.levelOf(): Int = (level as Var.Value).value

    fun reward(gold: Int): Reward = Reward(gold)

    /** Twice the gold of [reward]; fails unless it got a Kotlin Reward. */
    fun bonusOf(reward: Reward): Int = reward.gold * 2

    /** Gives back the function it got. */
    fun <T, R> pass(transform: (T) -> R): (T) -> R = transform

    /** Calls [block], swallowing anything it throws. */
    fun swallow(block: () -> Int): Int = runCatching(block).getOrDefault(0)

    /** Calls [block] with zero. */
    fun withZero(block: (Int) -> Int): Int = block(0)

    fun <T> Set<T>.again(): Set<T> {
        check(this is Set<*>) { "Not a Set." }
        return this
    }

    fun free(): Payment = Payment.Free

    /** Half of [ratio]; fails unless it got a Kotlin Float. */
    fun half(ratio: Float): Float = ratio / 2

    fun brokenMood(): Mood = Mood(Var.Computed(Formula("1")))
}
