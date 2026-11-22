package fixture

import com.typewritermc.types.Many
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.template
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.NamedFieldPatternSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ResourceMatchTemplate

@TypewriterType(id = "a0000000000000000000000000000621")
data class WeightedStep(
    val name: String,
) : Resource

// Each link of the gate sits in a record of a list, beside the weight it carries.
@TypewriterType(id = "a0000000000000000000000000000622")
data class WeightedChoice(
    val link: Ref<WeightedLinks.Gate, WeightedStep>,
    val weight: Int = 1,
)

@TypewriterType(id = "a0000000000000000000000000000623")
data class WeightedGate(
    val links: List<WeightedChoice> = emptyList(),
) : Resource

@ReferenceContract("a0000000000000000000000000000624")
interface WeightedLinksContract {
    interface Gate : Many<WeightedGate>

    interface Step : Many<WeightedStep>
}

fun main() {
    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "nested record link fixture"),
            StandardTypes.definitions +
                ResourceDefinition.definition +
                WeightedStepDefinition.definition +
                WeightedChoiceDefinition.definition +
                WeightedGateDefinition.definition +
                WeightedLinks.Gate.Definition.definition,
        )
    val choice = (catalog.resolve(WeightedChoiceDefinition.use.use) as Resolution.Ready).value
    val link = (catalog.resolve(choice.schema.fields.single { it.key == "link" }.type) as Resolution.Ready).value
    val binding = WeightedGateEndpointBindings.bindings.single()

    // The nested field is a link to the gate's endpoint, and the gate binds that endpoint at every item of its list.
    check((link.schema.representation as ResolvedRepresentation.LinkWrapper).value.endpoint == WeightedLinks.contract.first.id)
    check(binding.endpoint == WeightedLinks.contract.first.id)
    check(binding.valueOwner == WeightedChoiceDefinition.id)
    check(binding.containsCollection)
    check(binding.target == ResourceMatchTemplate.TypeWrapper(WeightedStepDefinition.id.template()))
    check(
        binding.relativePath.segments ==
            listOf(
                FieldPatternSegment.FieldWrapper(NamedFieldPatternSegment(name = "links")),
                FieldPatternSegment.ITEMS,
                FieldPatternSegment.FieldWrapper(NamedFieldPatternSegment(name = "link")),
            ),
    )
}
