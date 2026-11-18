package fixture

// The generated endpoint exists only from the second KSP round, so this case cannot share a compilation with first
// round diagnostics.

import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000631")
data class MixedBoard<A, B>(
    val first: List<A> = emptyList(),
    val second: List<B> = emptyList(),
) : Resource

@TypewriterType(id = "a0000000000000000000000000000632")
data class MixedPin(
    val board: Ref<MixedPins.Pin, MixedBoard<*, Int>>, // error: MixedPin.board.target: A resource reference target takes a star for every argument or for none.
) : Resource

@ReferenceContract("a0000000000000000000000000000633")
interface MixedPinsContract {
    interface Pin : Many<MixedPin>

    interface Board : One<MixedBoard<*, *>>
}
