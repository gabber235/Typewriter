package fixture

import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CatalogGeneration

@TypewriterType(id = "a0000000000000000000000000000080")
data class UniversalSource(
    val target: Ref<UniversalTarget.Source, Resource>,
) : Resource

@ReferenceContract("a0000000000000000000000000000081")
interface UniversalTargetContract {
    interface Source : One<UniversalSource>

    interface Target : One<Resource>
}

// A universal endpoint names Resource itself, so this module states Resource's definition.
@TypewriterTypeImports(Resource::class)
object UniversalTypeImports

fun main() {
    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "universal resource fixture"),
            StandardTypes.definitions +
                ResourceDefinition.definition +
                UniversalSourceDefinition.definition +
                UniversalTarget.Source.Definition.definition,
        )
    // A resource type is a Resource through the catalog's own rule, so a universal endpoint accepts it.
    check(catalog.isReadableAs(UniversalSourceDefinition.use.use, ResourceDefinition.use.use))
}
