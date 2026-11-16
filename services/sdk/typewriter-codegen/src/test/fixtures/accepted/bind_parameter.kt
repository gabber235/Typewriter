@file:JvmName("BindParameter")

package fixture

import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import com.typewritermc.formula.BindParameter
import com.typewritermc.types.catalog.BindKey
import io.kotest.matchers.shouldBe

/** A generic board: a bind block may compute any of its parameters from its content. */
@TypewriterType(id = "b1b00000000000000000000000000001")
data class Board<T, V>(
    val title: String = "",
    val items: List<T> = emptyList(),
    val values: List<V> = emptyList(),
) : Resource

/** A generic type that is not a resource: nothing can bind it, so it has no handles. */
@TypewriterType(id = "b1b00000000000000000000000000002")
data class Duo<T>(
    val first: T,
    val second: T,
)

/**
 * Every type parameter of a resource gets a handle naming its owner, with a draft of the board for its bind block to
 * read, and code leaves each one creator chosen: only a registered bind makes a parameter computed.
 */
fun main(args: Array<String>) {
    BoardDefinition.definition.parameters.map { it.name to it.derived } shouldBe listOf("T" to false, "V" to false)
    val handles: List<BindParameter<BoardDraft<Nothing, Nothing>>> = listOf(BoardBind.T, BoardBind.V)
    handles.map { it.key } shouldBe listOf(BindKey(BoardDefinition.id, "T"), BindKey(BoardDefinition.id, "V"))
    runCatching { Class.forName("fixture.DuoBind") }.isFailure shouldBe true
}
