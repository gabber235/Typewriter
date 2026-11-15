package fixture

// The generated endpoint exists only from the second KSP round, so this case cannot share a compilation with first
// round diagnostics.

import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000641")
data class NarrowBoard<V>(
    val rows: List<V> = emptyList(),
) : Resource

@TypewriterType(id = "a0000000000000000000000000000642")
data class NarrowPin(
    val board: Ref<NarrowPins.Pin, NarrowBoard<Int>>, // error: NarrowPin.board.target: Relation endpoint fixture.NarrowPins.Pin links to a star endpoint, so its links name the star: fixture.NarrowBoard<*>.
) : Resource

@ReferenceContract("a0000000000000000000000000000643")
interface NarrowPinsContract {
    interface Pin : Many<NarrowPin>

    interface Board : One<NarrowBoard<*>>
}
