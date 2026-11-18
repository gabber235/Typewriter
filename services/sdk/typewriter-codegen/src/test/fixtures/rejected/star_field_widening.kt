package fixture

// The generated endpoint exists only from the second KSP round, so this case cannot share a compilation with first
// round diagnostics.

import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000651")
data class WideBoard<V>(
    val rows: List<V> = emptyList(),
) : Resource

@TypewriterType(id = "a0000000000000000000000000000652")
data class WidePin(
    val board: Ref<WidePins.Pin, WideBoard<*>>, // error: WidePin.board.target: Relation endpoint fixture.WidePins.Pin links to a typed endpoint, so a star target would widen it.
) : Resource

@ReferenceContract("a0000000000000000000000000000653")
interface WidePinsContract {
    interface Pin : Many<WidePin>

    interface Board : One<WideBoard<Int>>
}
