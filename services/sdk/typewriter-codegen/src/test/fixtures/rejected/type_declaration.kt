package fixture

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.Resource
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

@TypewriterType(id = "a0000000000000000000000000000526")
@TypewriterDisplay(searchKey = "note")
data class SearchKeyedValue(val title: String) // error: TypewriterDisplay searchKey requires a type that implements Resource.

@TypewriterType(id = "a0000000000000000000000000000527")
@TypewriterDisplay(searchKey = "Main story")
data class InvalidSearchKey(val title: String) : Resource // error: TypewriterDisplay searchKey must be a lower case letter followed by lower case letters or digits, found Main story.

@TypewriterType(id = "a0000000000000000000000000000528")
@TypewriterDisplay(searchKey = "type")
data class TypeKeyed(val title: String) : Resource // error: TypewriterDisplay searchKey type is reserved for the editor's type selector; declare another searchKey.

@TypewriterType(id = "a0000000000000000000000000000529")
@TypewriterDisplay(icon = "Material Book")
data class InvalidIcon(val title: String) // error: TypewriterDisplay icon must use Iconify prefix:name syntax or inline SVG markup, found Material Book.
