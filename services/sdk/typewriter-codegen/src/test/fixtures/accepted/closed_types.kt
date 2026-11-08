package fixture

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CatalogGeneration
import com.typewritermc.types.member
import com.typewritermc.types.namedTemplate
import kotlinx.serialization.SerialName
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind

// An enum is a closed record of unit cases named by their serialized names.
@TypewriterType(id = "a0000000000000000000000000000901")
enum class Door { OPEN, @SerialName("shut") CLOSED }

// A sealed type lists its nested subtypes as cases named inside it.
@TypewriterType(id = "a0000000000000000000000000000902")
sealed interface NpcLocation {
    data class Spawned(val position: Int) : NpcLocation

    data object NotSpawned : NpcLocation
}

// Cases declared beside their sealed parent keep the order of the source, not of their names.
@TypewriterType(id = "a0000000000000000000000000000905")
sealed interface Weather

@TypewriterType(id = "a0000000000000000000000000000906")
data object Sunny : Weather

@TypewriterType(id = "a0000000000000000000000000000907")
data object Rainy : Weather

@TypewriterType(id = "a0000000000000000000000000000908")
data object Cloudy : Weather

// A sealed class is closed like a sealed interface: a value is always one of its cases, never the class itself.
@TypewriterType(id = "a0000000000000000000000000000909")
sealed class Reward {
    data class Coins(val amount: Int) : Reward()

    data object Empty : Reward()
}

// An interface that is not sealed stays open to subtypes from anywhere.
@TypewriterType(id = "a0000000000000000000000000000904")
interface Shape

fun main(args: Array<String>) {
    val door = DoorDefinition.declaration.representation as RepresentationTemplate.RecordWrapper
    check(door.value.form == RecordForm.createClosed(cases = listOf(DoorDefinition.id.member("OPEN").namedTemplate(), DoorDefinition.id.member("shut").namedTemplate())))
    check(DoorDefinition.cases.map { it.id } == listOf(DoorDefinition.id.member("OPEN"), DoorDefinition.id.member("shut")))
    check(DoorDefinition.cases.all { it.representation == RepresentationTemplate.createScalar(kind = ScalarKind.UNIT) })
    check(DoorDefinition.cases.all { it.parents == listOf(DoorDefinition.id.namedTemplate()) })

    val location = NpcLocationDefinition.declaration.representation as RepresentationTemplate.RecordWrapper
    val cases = (location.value.form as RecordForm.ClosedWrapper).value.cases.map { it.definition }
    check(cases.toSet() == setOf(NpcLocationDefinition.id.member("Spawned"), NpcLocationDefinition.id.member("NotSpawned")))
    check(NpcLocationSpawnedDefinition.id == NpcLocationDefinition.id.member("Spawned"))
    check(NpcLocationNotSpawnedDefinition.declaration.representation == RepresentationTemplate.createScalar(kind = ScalarKind.UNIT))
    check(NpcLocationSpawnedDefinition.declaration.parents == listOf(NpcLocationDefinition.id.namedTemplate()))

    val weather = (WeatherDefinition.declaration.representation as RepresentationTemplate.RecordWrapper).value.form
    check(weather == RecordForm.createClosed(cases = listOf(SunnyDefinition.id.namedTemplate(), RainyDefinition.id.namedTemplate(), CloudyDefinition.id.namedTemplate()))) { "$weather" }

    check((ShapeDefinition.declaration.representation as RepresentationTemplate.RecordWrapper).value.form == RecordForm.OPEN)

    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "closed fixture"),
            StandardTypes.definitions + RewardDefinition.definition + RewardCoinsDefinition.definition + RewardEmptyDefinition.definition,
        )
    val bindings = FactoryNativeBindingRegistry(catalog, listOf(RewardCoinsNativeBindingFactory, RewardEmptyNativeBindingFactory))
    val reward = (catalog.resolve(RewardDefinition.id.use()) as Resolution.Ready).value
    @Suppress("UNCHECKED_CAST")
    val binding = bindings.bind(reward) as NativeBinding<Any>
    listOf(Reward.Coins(amount = 3), Reward.Empty).forEach { original ->
        val encoded = binding.encode(original)
        val complete = (reward.complete(encoded) as CompletenessResult.Complete).value
        check(binding.decode(complete) == original) { "$original came back as ${binding.decode(complete)}" }
    }
}
