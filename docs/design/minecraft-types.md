# Minecraft value types

Value types that Minecraft capabilities and Paper extensions use in entry fields, formulas, and stored data. They live under the Minecraft capability; core primitives never depend on them (see [overview.md](overview.md)). Build order: layer 4 in [closed-beta-roadmap.md](closed-beta-roadmap.md).

## Space: world, vector, rotation

Spatial data has three parts: a **world**, a **vector** (x, y, z), and a **rotation** (yaw, pitch). Different uses need different combinations, so there is one exact type per real combination. An entry field always asks for exactly the type it needs; nothing in it is optional, and the panel shows exactly those parts (a particle field has no rotation to fill in).

| Type | Parts | Example use |
| --- | --- | --- |
| `Vec3` | vector | velocity, offsets, particle spread |
| `BlockVec` | whole number vector | a block offset |
| `Rotation` | rotation | "look in this direction" cue |
| `Pose` | vector + rotation | camera keyframe relative to a scene origin |
| `Location` | world + vector | particle spot, sound location, region center |
| `BlockLocation` | world + whole number vector | fake block, block events |
| `Position` | world + vector + rotation | teleport, NPC spawn |

A combination without a real use (world + rotation) gets no type until something needs it; adding one is a single data class.

### World

```kotlin
@JvmInline
@Serializable
@TypewriterType(id = "minecraft:world")
value class World(val key: String) // "minecraft:overworld", "myserver:arena"
```

A world is identified by its namespaced key (Paper `World.getKey()`), not by UUID or name. A UUID changes when a world is copied to another server, which breaks templates and multi server setups; a key is stable and readable. A reference to a key that no engine reports is a publication check diagnostic. The panel edits a world through a picker of the worlds the engines report.

### Part interfaces

Each part is an interface with a self type, so operations written once return the receiver's own type:

```kotlin
interface Vector { val x: Double; val y: Double; val z: Double }

interface InWorld<S : InWorld<S>> { val world: World; fun withWorld(world: World): S }
interface HasVector<S : HasVector<S>> : Vector { fun withVector(x: Double, y: Double, z: Double): S }
interface HasRotation<S : HasRotation<S>> { val yaw: Float; val pitch: Float; fun withRotation(yaw: Float, pitch: Float): S }
interface HasBlock<S : HasBlock<S>> { val x: Int; val y: Int; val z: Int; fun withBlock(x: Int, y: Int, z: Int): S }
```

In the catalog the part interfaces are abstract records; the exact types list them in `parents`. Entry fields never use a part interface as their type, so the polymorphic form picker never appears for spatial fields. Formula functions may take them.

### Exact types

Exact types are flat data classes, so the generated `copy` works per field and returns the same type. Each implements one line per part:

```kotlin
@Serializable
@TypewriterType(id = "minecraft:location")
data class Location(
    override val world: World,
    override val x: Double,
    override val y: Double,
    override val z: Double,
) : InWorld<Location>, HasVector<Location> {
    override fun withWorld(world: World) = copy(world = world)
    override fun withVector(x: Double, y: Double, z: Double) = copy(x = x, y = y, z = z)
}

@Serializable
@TypewriterType(id = "minecraft:position")
data class Position(
    override val world: World,
    override val x: Double,
    override val y: Double,
    override val z: Double,
    override val yaw: Float,
    override val pitch: Float,
) : InWorld<Position>, HasVector<Position>, HasRotation<Position> {
    override fun withWorld(world: World) = copy(world = world)
    override fun withVector(x: Double, y: Double, z: Double) = copy(x = x, y = y, z = z)
    override fun withRotation(yaw: Float, pitch: Float) = copy(yaw = yaw, pitch = pitch)
}
```

`Vec3`, `BlockVec`, `Rotation`, `Pose`, and `BlockLocation` follow the same pattern.

### Operations

Written once against the part interfaces; chaining keeps the type:

```kotlin
fun <S : HasVector<S>> S.add(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0): S =
    withVector(this.x + x, this.y + y, this.z + z)
operator fun <S : HasVector<S>> S.plus(v: Vector): S = add(v.x, v.y, v.z)
fun <S : HasVector<S>> S.lerp(to: Vector, t: Double): S = ...
fun <S> S.lookAt(target: Vector): S where S : HasVector<S>, S : HasRotation<S> = ...

spawn.copy(y = 64.0).add(z = 2.0).withWorld(arena) // a Location
```

Switching between types is explicit, through plain properties and functions:

```kotlin
position.location     // drop the rotation
location.with(rotation) // a Position
location.block        // a BlockLocation (floor)
blockLocation.center  // a Location
```

### Distance

Distance between values that have a world respects the world: values in different worlds have no distance, as in legacy (`Position.kt` on `origin/develop`).

```kotlin
fun Vector.distance(other: Vector): Double // Vec3, Pose
fun <A, B> A.distance(other: B): Double?   // null across worlds
    where A : InWorld<A>, A : Vector, B : InWorld<B>, B : Vector
fun <A, B> A.isInRange(other: B, range: Double): Boolean // false across worlds
    where A : InWorld<A>, A : Vector, B : InWorld<B>, B : Vector
```

In a formula:

```
protagonist.location.isInRange(npc_spot, 5)
spawn.copy(y = 64).add(z = 2)
```

### Panel

Each exact type has its own editor showing exactly its parts. Capture (layer 13) fills exactly those parts from the player; teleport to a `Location` keeps the player's current facing.

## Requirements on other layers

- Formula type checker (layer 1): bounded generics (`S : HasVector<S>`) and `where` clauses with several bounds.

## Open

- Verify in layer 4 that Kotlin overload resolution picks the world aware `distance` for `Location` and `Position` over `Vector.distance`; if not, the worldless version gets its own name.
- Items, registry ids (sound, particle, material, entity type, potion effect), and sounds are not designed yet.
