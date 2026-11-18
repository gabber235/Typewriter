package fixture

import com.typewritermc.formula.TypewriterFormulaProvider

class Unmapped

@TypewriterFormulaProvider
object Bad {
    fun two(f: (Int, Int) -> Int): Int = f(1, 2) // error: Name each parameter of a function type with two or more parameters.

    fun Int.plus(other: Int): Int = 0 // error: A member of Int hides plus. Give it another Kotlin name and @TypewriterFormulaName.

    fun many(a: Int = 1, b: Int = 2, c: Int = 3, d: Int = 4, e: Int = 5): Int = 0 // error: A formula provider function can default at most four parameters.

    fun four(f: (a: Int, b: Int, c: Int, d: Int) -> Int): Int = 0 // error: A function parameter can have at most three parameters.

    fun Unmapped.x(): Int = 1 // error: Unmapped has no catalog type.

    suspend fun later(): Int = 1 // error: A formula provider function cannot suspend.

    fun spread(vararg values: Int): Int = 0 // error: A formula provider function cannot take a vararg.
}

@TypewriterFormulaProvider
class NotAnObject // error: A formula provider must be an object.

@TypewriterFormulaProvider
private object Hidden // error: A formula provider must be visible.
