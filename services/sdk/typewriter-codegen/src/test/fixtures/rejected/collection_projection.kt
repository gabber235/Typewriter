package fixture

import com.typewritermc.presentation.CollectionProjection
import com.typewritermc.presentation.TypewriterCollectionProjection

object Holder {
    @TypewriterCollectionProjection
    fun member(): CollectionProjection<*, *, *> = TODO() // error: Collection projections must be visible top level functions.
}

@TypewriterCollectionProjection
fun withParameter(name: String): CollectionProjection<*, *, *> = TODO() // error: Collection projection functions must be qualified synchronous functions without parameters.

@TypewriterCollectionProjection
fun wrongResult(): String = "" // error: Collection projection functions must return CollectionProjection.
