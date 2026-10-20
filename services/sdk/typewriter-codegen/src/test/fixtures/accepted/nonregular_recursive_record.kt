package fixture

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.Resource
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeUse
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve

@TypewriterType(id = "a0000000000000000000000000000050")
data class RecursiveSource(
    val nested: Nest<String> = Nest(),
) : Resource

@TypewriterType(id = "a0000000000000000000000000000051")
data class Nest<T>(
    val value: T? = null,
    val next: Nest<List<T>>? = null,
)

fun main() {
    val catalog = DefaultCheckedCatalog(
        CatalogGeneration("recursive fixture"),
        StandardTypes.definitions + NestDefinition.definition + RecursiveSourceDefinition.definition,
    )
    val bindings = FactoryNativeBindingRegistry(catalog, listOf(NestNativeBindingFactory, RecursiveSourceNativeBindingFactory))
    val text = TypeUse.Scalar(ScalarKind.Text)
    fun roundTrip(type: TypeUse.Named, original: Any) {
        val checked = (catalog.resolve(type) as Resolution.Ready).value
        @Suppress("UNCHECKED_CAST")
        val binding = bindings.bind(checked) as NativeBinding<Any>
        val signature = binding.signature
        val encoded = binding.encode(original)
        val complete = (checked.complete(encoded) as CompletenessResult.Complete).value
        check(binding.decode(complete) == original)
        check(binding.signature == signature)
    }
    roundTrip(NestDefinition.applied(listOf(text)), Nest<String>())
    roundTrip(NestDefinition.applied(listOf(text)), Nest(value = "root", next = Nest<List<String>>(value = listOf("child"))))
    roundTrip(NestDefinition.applied(listOf(TypeUse.Named(StandardTypes.list, listOf(text)))), Nest<List<String>>(value = emptyList()))
    roundTrip(RecursiveSourceDefinition.use, RecursiveSource())
}
