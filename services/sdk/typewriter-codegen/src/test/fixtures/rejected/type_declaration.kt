package fixture

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.SerialName

@TypewriterType(id = "a0000000000000000000000000000521")
private data class HiddenType(val title: String) // error: Typewriter types must be visible qualified declarations.

@TypewriterType(id = "not-a-uuid")
data class MalformedId(val title: String) // error: Typewriter type ids must be UUIDs.

@TypewriterType(id = "a0000000000000000000000000000522")
@TypewriterDisplay(name = "Red", icon = "mdi:circle", color = "red")
data class InvalidDisplay(val title: String) // error: TypewriterDisplay color must use #RRGGBB syntax, found red.

@TypewriterType(id = "a0000000000000000000000000000523")
data class UnownedField(val artifact: ArtifactId) // error: Type kotlin/com.typewritermc.imprint.ArtifactId has no generated definition; declare it with @TypewriterType or import it with @TypewriterTypeImports.

@TypewriterType(id = "a0000000000000000000000000000524")
interface Titled {
    @SerialName("heading")
    val title: String
}

@TypewriterType(id = "a0000000000000000000000000000525")
data class Retitled( // error: Authoring property title maps to conflicting serialized fields; preserve its inherited serialized name.
    @SerialName("caption")
    override val title: String,
) : Titled
