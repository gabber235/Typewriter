package fixture

import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000621")
data class ShapedPair<A, B>(
    val first: List<A> = emptyList(),
    val second: List<B> = emptyList(),
) : Resource

@TypewriterType(id = "a0000000000000000000000000000622")
data class ShapedHolder(
    val name: String = "",
) : Resource

@TypewriterType(id = "a0000000000000000000000000000623")
data class ShapedBox<T>(
    val items: List<T> = emptyList(),
) : Resource

@ReferenceContract("a0000000000000000000000000000624")
interface MixedStarContract { // error: Reference contracts require exactly two One or Many endpoint declarations.
    interface Holder : Many<ShapedHolder>

    interface Pair : One<ShapedPair<*, Int>> // error: Relation endpoint resources take a star for every argument or for none.
}

@ReferenceContract("a0000000000000000000000000000625")
interface NestedStarContract { // error: Reference contracts require exactly two One or Many endpoint declarations.
    interface Holder : Many<ShapedHolder>

    interface Box : One<ShapedBox<ShapedPair<*, *>>> // error: Relation endpoint resources take stars only as their own arguments, never inside one.
}
