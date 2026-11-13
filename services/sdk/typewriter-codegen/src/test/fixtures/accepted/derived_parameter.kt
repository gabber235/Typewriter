@file:JvmName("DerivedParameter")

package fixture

import com.typewritermc.types.Derived
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.catalog.DerivedKey
import io.kotest.matchers.shouldBe

/** A board whose value type its own content derives, next to an item type a creator chooses. */
@TypewriterType(id = "b1b00000000000000000000000000001")
data class Board<T, @Derived V>(
    val title: String = "",
    val items: List<T> = emptyList(),
    val values: List<V> = emptyList(),
) : Resource

/** The catalog marks only the derived parameter, and its handle names the parameter. */
fun main(args: Array<String>) {
    BoardDefinition.definition.parameters.map { it.name to it.derived } shouldBe listOf("T" to false, "V" to true)
    BoardDerived.V shouldBe DerivedKey("V")
}
