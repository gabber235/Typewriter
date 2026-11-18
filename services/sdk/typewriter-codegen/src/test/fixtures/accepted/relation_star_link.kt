package fixture

import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ResourceMatch
import skirout.editor.v1.type_catalog.ResourceMatchTemplate

@TypewriterType(id = "a0000000000000000000000000000611")
data class StarBoard<V>(
    val rows: List<V> = emptyList(),
) : Resource

// The pin's field names the star its endpoint's opposite admits: any board, whatever its rows.
@TypewriterType(id = "a0000000000000000000000000000612")
data class StarPin(
    val board: Ref<StarPins.Pin, StarBoard<*>>,
) : Resource

@ReferenceContract("a0000000000000000000000000000613")
interface StarPinsContract {
    interface Pin : Many<StarPin>

    interface Board : One<StarBoard<*>>
}

fun main() {
    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "star link fixture"),
            StandardTypes.definitions +
                ResourceDefinition.definition +
                StarBoardDefinition.definition +
                StarPinDefinition.definition +
                StarPins.Pin.Definition.definition,
        )
    val pin = (catalog.resolve(StarPinDefinition.use.use) as Resolution.Ready).value
    val board = (catalog.resolve(pin.schema.fields.single().type) as Resolution.Ready).value
    val link = (board.schema.representation as ResolvedRepresentation.LinkWrapper).value

    // The star endpoint admits a board of any rows, and the link to it names that definition, not a type.
    check(StarPins.contract.second.resource == ResourceMatchTemplate.DefinitionWrapper(StarBoardDefinition.id))
    check(StarPins.Pin.Definition.definition.parameters.isEmpty())
    check(link.endpoint == StarPins.contract.first.id)
    check(link.target == ResourceMatch.DefinitionWrapper(StarBoardDefinition.id))
    check(StarPinEndpointBindings.bindings.single().target == ResourceMatchTemplate.DefinitionWrapper(StarBoardDefinition.id))
}
