package fixture

import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterTypeImports

@TypewriterRecordContract
interface Left {
    val title: String
}

@TypewriterRecordContract
interface Right {
    val title: String
}

interface Ambiguous :
    Left,
    Right

@TypewriterTypeImports(Ambiguous::class)
object ImportedTypes
