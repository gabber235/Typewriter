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

    check((ShapeDefinition.declaration.representation as RepresentationTemplate.RecordWrapper).value.form == RecordForm.OPEN)
}
