package fixture

import com.typewritermc.types.TypewriterType
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
}
