import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter/models/mc_version.dart";
import "package:typewriter/utils/icons.dart";

part "materials.freezed.dart";
part "materials.g.dart";

enum MaterialProperty {
  item(TWIcons.magicWand, Colors.blue, "Item"),
  block(TWIcons.cube, Colors.green, "Block"),
  solid(TWIcons.square, Colors.brown, "Solid"),
  transparent(TWIcons.squareOutline, Colors.white, "Transparent"),
  intractable(TWIcons.handPointUp, Colors.pink, "Intractable"),
  occluding(TWIcons.eye, Colors.black, "Occluding"),
  record(TWIcons.recordVinyl, Colors.grey, "Record"),
  tool(TWIcons.hammer, Colors.teal, "Tool"),
  weapon(TWIcons.swords, Colors.red, "Weapon"),
  armor(TWIcons.armor, Colors.blue, "Armor"),
  flammable(TWIcons.fire, Colors.red, "Flammable"),
  burnable(TWIcons.wallFire, Colors.orange, "Burnable"),
  edible(TWIcons.burger, Colors.yellow, "Edible"),
  fuel(TWIcons.gasPump, Colors.purple, "Fuel"),
  ore(TWIcons.ore, Colors.amber, "Ore"),
  ;

  const MaterialProperty(this.icon, this.color, this.name);

  final String icon;
  final Color color;

  final String name;
}

const Map<String, MinecraftMaterial> materials = {
  "acacia_boat": MinecraftMaterial(
    name: "Acacia Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/acacia_boat.png",
  ),
  "acacia_button": MinecraftMaterial(
    name: "Acacia Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/acacia_button.png",
  ),
  "acacia_chest_boat": MinecraftMaterial(
    name: "Acacia Chest Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/acacia_chest_boat.png",
  ),
  "acacia_door": MinecraftMaterial(
    name: "Acacia Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_door.png",
  ),
  "acacia_fence": MinecraftMaterial(
    name: "Acacia Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_fence.png",
  ),
  "acacia_fence_gate": MinecraftMaterial(
    name: "Acacia Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_fence_gate.png",
  ),
  "acacia_hanging_sign": MinecraftMaterial(
    name: "Acacia Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/acacia_hanging_sign.png",
  ),
  "acacia_leaves": MinecraftMaterial(
    name: "Acacia Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_leaves.png",
  ),
  "acacia_log": MinecraftMaterial(
    name: "Acacia Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_log.png",
  ),
  "acacia_planks": MinecraftMaterial(
    name: "Acacia Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_planks.png",
  ),
  "acacia_pressure_plate": MinecraftMaterial(
    name: "Acacia Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_pressure_plate.png",
  ),
  "acacia_sapling": MinecraftMaterial(
    name: "Acacia Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/acacia_sapling.png",
  ),
  "acacia_sign": MinecraftMaterial(
    name: "Acacia Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_sign.png",
  ),
  "acacia_slab": MinecraftMaterial(
    name: "Acacia Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_slab.png",
  ),
  "acacia_stairs": MinecraftMaterial(
    name: "Acacia Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_stairs.png",
  ),
  "acacia_trapdoor": MinecraftMaterial(
    name: "Acacia Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_trapdoor.png",
  ),
  "acacia_wood": MinecraftMaterial(
    name: "Acacia Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_wood.png",
  ),
  "activator_rail": MinecraftMaterial(
    name: "Activator Rail",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/activator_rail.png",
  ),
  "air": MinecraftMaterial(
    name: "Air",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/air.png",
  ),
  "allay_spawn_egg": MinecraftMaterial(
    name: "Allay Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/allay_spawn_egg.png",
  ),
  "allium": MinecraftMaterial(
    name: "Allium",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/allium.png",
  ),
  "amethyst_block": MinecraftMaterial(
    name: "Amethyst Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/amethyst_block.png",
  ),
  "amethyst_cluster": MinecraftMaterial(
    name: "Amethyst Cluster",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/amethyst_cluster.png",
  ),
  "amethyst_shard": MinecraftMaterial(
    name: "Amethyst Shard",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/amethyst_shard.png",
  ),
  "ancient_debris": MinecraftMaterial(
    name: "Ancient Debris",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/ancient_debris.png",
  ),
  "andesite": MinecraftMaterial(
    name: "Andesite",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/andesite.png",
  ),
  "andesite_slab": MinecraftMaterial(
    name: "Andesite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/andesite_slab.png",
  ),
  "andesite_stairs": MinecraftMaterial(
    name: "Andesite Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/andesite_stairs.png",
  ),
  "andesite_wall": MinecraftMaterial(
    name: "Andesite Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/andesite_wall.png",
  ),
  "angler_pottery_sherd": MinecraftMaterial(
    name: "Angler Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/angler_pottery_sherd.png",
  ),
  "anvil": MinecraftMaterial(
    name: "Anvil",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/anvil.png",
  ),
  "apple": MinecraftMaterial(
    name: "Apple",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/apple.png",
  ),
  "archer_pottery_sherd": MinecraftMaterial(
    name: "Archer Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/archer_pottery_sherd.png",
  ),
  "armadillo_scute": MinecraftMaterial(
    name: "Armadillo Scute",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/armadillo_scute.png",
  ),
  "armadillo_spawn_egg": MinecraftMaterial(
    name: "Armadillo Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/armadillo_spawn_egg.png",
  ),
  "armor_stand": MinecraftMaterial(
    name: "Armor Stand",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/armor_stand.png",
  ),
  "arms_up_pottery_sherd": MinecraftMaterial(
    name: "Arms Up Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/arms_up_pottery_sherd.png",
  ),
  "arrow": MinecraftMaterial(
    name: "Arrow",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/arrow.png",
  ),
  "axolotl_bucket": MinecraftMaterial(
    name: "Axolotl Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/axolotl_bucket.png",
  ),
  "axolotl_spawn_egg": MinecraftMaterial(
    name: "Axolotl Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/axolotl_spawn_egg.png",
  ),
  "azalea": MinecraftMaterial(
    name: "Azalea",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/azalea.png",
  ),
  "azalea_leaves": MinecraftMaterial(
    name: "Azalea Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/azalea_leaves.png",
  ),
  "azure_bluet": MinecraftMaterial(
    name: "Azure Bluet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/azure_bluet.png",
  ),
  "baked_potato": MinecraftMaterial(
    name: "Baked Potato",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/baked_potato.png",
  ),
  "bamboo": MinecraftMaterial(
    name: "Bamboo",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/bamboo.png",
  ),
  "bamboo_block": MinecraftMaterial(
    name: "Block of Bamboo",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_block.png",
  ),
  "bamboo_button": MinecraftMaterial(
    name: "Bamboo Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_button.png",
  ),
  "bamboo_chest_raft": MinecraftMaterial(
    name: "Bamboo Raft with Chest",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_chest_raft.png",
  ),
  "bamboo_door": MinecraftMaterial(
    name: "Bamboo Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_door.png",
  ),
  "bamboo_fence": MinecraftMaterial(
    name: "Bamboo Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_fence.png",
  ),
  "bamboo_fence_gate": MinecraftMaterial(
    name: "Bamboo Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_fence_gate.png",
  ),
  "bamboo_hanging_sign": MinecraftMaterial(
    name: "Bamboo Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_hanging_sign.png",
  ),
  "bamboo_mosaic": MinecraftMaterial(
    name: "Bamboo Mosaic",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_mosaic.png",
  ),
  "bamboo_mosaic_slab": MinecraftMaterial(
    name: "Bamboo Mosaic Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_mosaic_slab.png",
  ),
  "bamboo_mosaic_stairs": MinecraftMaterial(
    name: "Bamboo Mosaic Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_mosaic_stairs.png",
  ),
  "bamboo_planks": MinecraftMaterial(
    name: "Bamboo Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_planks.png",
  ),
  "bamboo_pressure_plate": MinecraftMaterial(
    name: "Bamboo Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_pressure_plate.png",
  ),
  "bamboo_raft": MinecraftMaterial(
    name: "Bamboo Raft",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_raft.png",
  ),
  "bamboo_sign": MinecraftMaterial(
    name: "Bamboo Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_sign.png",
  ),
  "bamboo_slab": MinecraftMaterial(
    name: "Bamboo Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_slab.png",
  ),
  "bamboo_stairs": MinecraftMaterial(
    name: "Bamboo Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_stairs.png",
  ),
  "bamboo_trapdoor": MinecraftMaterial(
    name: "Bamboo Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bamboo_trapdoor.png",
  ),
  "barrel": MinecraftMaterial(
    name: "Barrel",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/barrel.png",
  ),
  "barrier": MinecraftMaterial(
    name: "Barrier",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/barrier.png",
  ),
  "basalt": MinecraftMaterial(
    name: "Basalt",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/basalt.png",
  ),
  "bat_spawn_egg": MinecraftMaterial(
    name: "Bat Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bat_spawn_egg.png",
  ),
  "beacon": MinecraftMaterial(
    name: "Beacon",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/beacon.png",
  ),
  "bedrock": MinecraftMaterial(
    name: "Bedrock",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/bedrock.png",
  ),
  "bee_nest": MinecraftMaterial(
    name: "Bee Nest",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/bee_nest.png",
  ),
  "bee_spawn_egg": MinecraftMaterial(
    name: "Bee Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bee_spawn_egg.png",
  ),
  "beef": MinecraftMaterial(
    name: "Beef",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/beef.png",
  ),
  "beehive": MinecraftMaterial(
    name: "Beehive",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/beehive.png",
  ),
  "beetroot": MinecraftMaterial(
    name: "Beetroot",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/beetroot.png",
  ),
  "beetroot_seeds": MinecraftMaterial(
    name: "Beetroot Seeds",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/beetroot_seeds.png",
  ),
  "beetroot_soup": MinecraftMaterial(
    name: "Beetroot Soup",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/beetroot_soup.png",
  ),
  "bell": MinecraftMaterial(
    name: "Bell",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/bell.png",
  ),
  "big_dripleaf": MinecraftMaterial(
    name: "Big Dripleaf",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/big_dripleaf.png",
  ),
  "birch_boat": MinecraftMaterial(
    name: "Birch Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/birch_boat.png",
  ),
  "birch_button": MinecraftMaterial(
    name: "Birch Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/birch_button.png",
  ),
  "birch_chest_boat": MinecraftMaterial(
    name: "Birch Chest Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/birch_chest_boat.png",
  ),
  "birch_door": MinecraftMaterial(
    name: "Birch Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_door.png",
  ),
  "birch_fence": MinecraftMaterial(
    name: "Birch Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_fence.png",
  ),
  "birch_fence_gate": MinecraftMaterial(
    name: "Birch Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_fence_gate.png",
  ),
  "birch_hanging_sign": MinecraftMaterial(
    name: "Birch Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/birch_hanging_sign.png",
  ),
  "birch_leaves": MinecraftMaterial(
    name: "Birch Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_leaves.png",
  ),
  "birch_log": MinecraftMaterial(
    name: "Birch Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_log.png",
  ),
  "birch_planks": MinecraftMaterial(
    name: "Birch Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_planks.png",
  ),
  "birch_pressure_plate": MinecraftMaterial(
    name: "Birch Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_pressure_plate.png",
  ),
  "birch_sapling": MinecraftMaterial(
    name: "Birch Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/birch_sapling.png",
  ),
  "birch_sign": MinecraftMaterial(
    name: "Birch Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_sign.png",
  ),
  "birch_slab": MinecraftMaterial(
    name: "Birch Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_slab.png",
  ),
  "birch_stairs": MinecraftMaterial(
    name: "Birch Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_stairs.png",
  ),
  "birch_trapdoor": MinecraftMaterial(
    name: "Birch Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_trapdoor.png",
  ),
  "birch_wood": MinecraftMaterial(
    name: "Birch Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_wood.png",
  ),
  "black_banner": MinecraftMaterial(
    name: "Black Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/black_banner.png",
  ),
  "black_bed": MinecraftMaterial(
    name: "Black Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/black_bed.png",
  ),
  "black_bundle": MinecraftMaterial(
    name: "Black Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/black_bundle.png",
  ),
  "black_candle": MinecraftMaterial(
    name: "Black Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/black_candle.png",
  ),
  "black_carpet": MinecraftMaterial(
    name: "Black Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/black_carpet.png",
  ),
  "black_concrete": MinecraftMaterial(
    name: "Black Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_concrete.png",
  ),
  "black_concrete_powder": MinecraftMaterial(
    name: "Black Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_concrete_powder.png",
  ),
  "black_dye": MinecraftMaterial(
    name: "Black Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/black_dye.png",
  ),
  "black_glazed_terracotta": MinecraftMaterial(
    name: "Black Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_glazed_terracotta.png",
  ),
  "black_harness": MinecraftMaterial(
    name: "Black Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/black_harness.png",
  ),
  "black_shulker_box": MinecraftMaterial(
    name: "Black Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_shulker_box.png",
  ),
  "black_stained_glass": MinecraftMaterial(
    name: "Black Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_stained_glass.png",
  ),
  "black_stained_glass_pane": MinecraftMaterial(
    name: "Black Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_stained_glass_pane.png",
  ),
  "black_terracotta": MinecraftMaterial(
    name: "Black Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_terracotta.png",
  ),
  "black_wool": MinecraftMaterial(
    name: "Black Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/black_wool.png",
  ),
  "blackstone": MinecraftMaterial(
    name: "Blackstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blackstone.png",
  ),
  "blackstone_slab": MinecraftMaterial(
    name: "Blackstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blackstone_slab.png",
  ),
  "blackstone_stairs": MinecraftMaterial(
    name: "Blackstone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blackstone_stairs.png",
  ),
  "blackstone_wall": MinecraftMaterial(
    name: "Blackstone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blackstone_wall.png",
  ),
  "blade_pottery_sherd": MinecraftMaterial(
    name: "Blade Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blade_pottery_sherd.png",
  ),
  "blast_furnace": MinecraftMaterial(
    name: "Blast Furnace",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blast_furnace.png",
  ),
  "blaze_powder": MinecraftMaterial(
    name: "Blaze Powder",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blaze_powder.png",
  ),
  "blaze_rod": MinecraftMaterial(
    name: "Blaze Rod",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/blaze_rod.png",
  ),
  "blaze_spawn_egg": MinecraftMaterial(
    name: "Blaze Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blaze_spawn_egg.png",
  ),
  "blue_banner": MinecraftMaterial(
    name: "Blue Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/blue_banner.png",
  ),
  "blue_bed": MinecraftMaterial(
    name: "Blue Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/blue_bed.png",
  ),
  "blue_bundle": MinecraftMaterial(
    name: "Blue Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blue_bundle.png",
  ),
  "blue_candle": MinecraftMaterial(
    name: "Blue Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/blue_candle.png",
  ),
  "blue_carpet": MinecraftMaterial(
    name: "Blue Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/blue_carpet.png",
  ),
  "blue_concrete": MinecraftMaterial(
    name: "Blue Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_concrete.png",
  ),
  "blue_concrete_powder": MinecraftMaterial(
    name: "Blue Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_concrete_powder.png",
  ),
  "blue_dye": MinecraftMaterial(
    name: "Blue Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blue_dye.png",
  ),
  "blue_egg": MinecraftMaterial(
    name: "Blue Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blue_egg.png",
  ),
  "blue_glazed_terracotta": MinecraftMaterial(
    name: "Blue Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_glazed_terracotta.png",
  ),
  "blue_harness": MinecraftMaterial(
    name: "Blue Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blue_harness.png",
  ),
  "blue_ice": MinecraftMaterial(
    name: "Blue Ice",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_ice.png",
  ),
  "blue_orchid": MinecraftMaterial(
    name: "Blue Orchid",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/blue_orchid.png",
  ),
  "blue_shulker_box": MinecraftMaterial(
    name: "Blue Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_shulker_box.png",
  ),
  "blue_stained_glass": MinecraftMaterial(
    name: "Blue Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_stained_glass.png",
  ),
  "blue_stained_glass_pane": MinecraftMaterial(
    name: "Blue Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_stained_glass_pane.png",
  ),
  "blue_terracotta": MinecraftMaterial(
    name: "Blue Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_terracotta.png",
  ),
  "blue_wool": MinecraftMaterial(
    name: "Blue Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/blue_wool.png",
  ),
  "bogged_spawn_egg": MinecraftMaterial(
    name: "Bogged Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bogged_spawn_egg.png",
  ),
  "bolt_armor_trim_smithing_template": MinecraftMaterial(
    name: "Bolt Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bolt_armor_trim_smithing_template.png",
  ),
  "bone": MinecraftMaterial(
    name: "Bone",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bone.png",
  ),
  "bone_block": MinecraftMaterial(
    name: "Bone Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/bone_block.png",
  ),
  "bone_meal": MinecraftMaterial(
    name: "Bone Meal",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bone_meal.png",
  ),
  "book": MinecraftMaterial(
    name: "Book",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/book.png",
  ),
  "bookshelf": MinecraftMaterial(
    name: "Bookshelf",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/bookshelf.png",
  ),
  "bordure_indented_banner_pattern": MinecraftMaterial(
    name: "Bordure Indented Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bordure_indented_banner_pattern.png",
  ),
  "bow": MinecraftMaterial(
    name: "Bow",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/bow.png",
  ),
  "bowl": MinecraftMaterial(
    name: "Bowl",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/bowl.png",
  ),
  "brain_coral": MinecraftMaterial(
    name: "Brain Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/brain_coral.png",
  ),
  "brain_coral_block": MinecraftMaterial(
    name: "Brain Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brain_coral_block.png",
  ),
  "brain_coral_fan": MinecraftMaterial(
    name: "Brain Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/brain_coral_fan.png",
  ),
  "bread": MinecraftMaterial(
    name: "Bread",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/bread.png",
  ),
  "breeze_rod": MinecraftMaterial(
    name: "Breeze Rod",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/breeze_rod.png",
  ),
  "breeze_spawn_egg": MinecraftMaterial(
    name: "Breeze Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/breeze_spawn_egg.png",
  ),
  "brewer_pottery_sherd": MinecraftMaterial(
    name: "Brewer Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brewer_pottery_sherd.png",
  ),
  "brewing_stand": MinecraftMaterial(
    name: "Brewing Stand",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brewing_stand.png",
  ),
  "brick": MinecraftMaterial(
    name: "Brick",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brick.png",
  ),
  "brick_slab": MinecraftMaterial(
    name: "Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brick_slab.png",
  ),
  "brick_stairs": MinecraftMaterial(
    name: "Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brick_stairs.png",
  ),
  "brick_wall": MinecraftMaterial(
    name: "Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brick_wall.png",
  ),
  "bricks": MinecraftMaterial(
    name: "Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/bricks.png",
  ),
  "brown_banner": MinecraftMaterial(
    name: "Brown Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/brown_banner.png",
  ),
  "brown_bed": MinecraftMaterial(
    name: "Brown Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/brown_bed.png",
  ),
  "brown_bundle": MinecraftMaterial(
    name: "Brown Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brown_bundle.png",
  ),
  "brown_candle": MinecraftMaterial(
    name: "Brown Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/brown_candle.png",
  ),
  "brown_carpet": MinecraftMaterial(
    name: "Brown Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/brown_carpet.png",
  ),
  "brown_concrete": MinecraftMaterial(
    name: "Brown Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_concrete.png",
  ),
  "brown_concrete_powder": MinecraftMaterial(
    name: "Brown Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_concrete_powder.png",
  ),
  "brown_dye": MinecraftMaterial(
    name: "Brown Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brown_dye.png",
  ),
  "brown_egg": MinecraftMaterial(
    name: "Brown Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brown_egg.png",
  ),
  "brown_glazed_terracotta": MinecraftMaterial(
    name: "Brown Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_glazed_terracotta.png",
  ),
  "brown_harness": MinecraftMaterial(
    name: "Brown Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brown_harness.png",
  ),
  "brown_mushroom": MinecraftMaterial(
    name: "Brown Mushroom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/brown_mushroom.png",
  ),
  "brown_mushroom_block": MinecraftMaterial(
    name: "Brown Mushroom Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/brown_mushroom_block.png",
  ),
  "brown_shulker_box": MinecraftMaterial(
    name: "Brown Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_shulker_box.png",
  ),
  "brown_stained_glass": MinecraftMaterial(
    name: "Brown Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_stained_glass.png",
  ),
  "brown_stained_glass_pane": MinecraftMaterial(
    name: "Brown Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_stained_glass_pane.png",
  ),
  "brown_terracotta": MinecraftMaterial(
    name: "Brown Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_terracotta.png",
  ),
  "brown_wool": MinecraftMaterial(
    name: "Brown Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/brown_wool.png",
  ),
  "brush": MinecraftMaterial(
    name: "Brush",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brush.png",
  ),
  "bubble_coral": MinecraftMaterial(
    name: "Bubble Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bubble_coral.png",
  ),
  "bubble_coral_block": MinecraftMaterial(
    name: "Bubble Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/bubble_coral_block.png",
  ),
  "bubble_coral_fan": MinecraftMaterial(
    name: "Bubble Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bubble_coral_fan.png",
  ),
  "bucket": MinecraftMaterial(
    name: "Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bucket.png",
  ),
  "budding_amethyst": MinecraftMaterial(
    name: "Budding Amethyst",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/budding_amethyst.png",
  ),
  "bundle": MinecraftMaterial(
    name: "Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bundle.png",
  ),
  "burn_pottery_sherd": MinecraftMaterial(
    name: "Burn Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/burn_pottery_sherd.png",
  ),
  "bush": MinecraftMaterial(
    name: "Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bush.png",
  ),
  "cactus": MinecraftMaterial(
    name: "Cactus",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cactus.png",
  ),
  "cactus_flower": MinecraftMaterial(
    name: "Cactus Flower",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cactus_flower.png",
  ),
  "cake": MinecraftMaterial(
    name: "Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cake.png",
  ),
  "calcite": MinecraftMaterial(
    name: "Calcite",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/calcite.png",
  ),
  "calibrated_sculk_sensor": MinecraftMaterial(
    name: "Calibrated Sculk Sensor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/calibrated_sculk_sensor.png",
  ),
  "camel_spawn_egg": MinecraftMaterial(
    name: "Camel Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/camel_spawn_egg.png",
  ),
  "campfire": MinecraftMaterial(
    name: "Campfire",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/campfire.png",
  ),
  "candle": MinecraftMaterial(
    name: "Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/candle.png",
  ),
  "carrot": MinecraftMaterial(
    name: "Carrot",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/carrot.png",
  ),
  "carrot_on_a_stick": MinecraftMaterial(
    name: "Carrot On A Stick",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/carrot_on_a_stick.png",
  ),
  "cartography_table": MinecraftMaterial(
    name: "Cartography Table",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/cartography_table.png",
  ),
  "carved_pumpkin": MinecraftMaterial(
    name: "Carved Pumpkin",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/carved_pumpkin.png",
  ),
  "cat_spawn_egg": MinecraftMaterial(
    name: "Cat Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cat_spawn_egg.png",
  ),
  "cauldron": MinecraftMaterial(
    name: "Cauldron",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cauldron.png",
  ),
  "cave_spider_spawn_egg": MinecraftMaterial(
    name: "Cave Spider Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cave_spider_spawn_egg.png",
  ),
  "chain_command_block": MinecraftMaterial(
    name: "Chain Command Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chain_command_block.png",
  ),
  "chainmail_boots": MinecraftMaterial(
    name: "Chainmail Boots",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/chainmail_boots.png",
  ),
  "chainmail_chestplate": MinecraftMaterial(
    name: "Chainmail Chestplate",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/chainmail_chestplate.png",
  ),
  "chainmail_helmet": MinecraftMaterial(
    name: "Chainmail Helmet",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/chainmail_helmet.png",
  ),
  "chainmail_leggings": MinecraftMaterial(
    name: "Chainmail Leggings",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/chainmail_leggings.png",
  ),
  "charcoal": MinecraftMaterial(
    name: "Charcoal",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/charcoal.png",
  ),
  "cherry_boat": MinecraftMaterial(
    name: "Cherry Boat",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_boat.png",
  ),
  "cherry_button": MinecraftMaterial(
    name: "Cherry Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_button.png",
  ),
  "cherry_chest_boat": MinecraftMaterial(
    name: "Cherry Boat with Chest",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_chest_boat.png",
  ),
  "cherry_door": MinecraftMaterial(
    name: "Cherry Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_door.png",
  ),
  "cherry_fence": MinecraftMaterial(
    name: "Cherry Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_fence.png",
  ),
  "cherry_fence_gate": MinecraftMaterial(
    name: "Cherry Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_fence_gate.png",
  ),
  "cherry_hanging_sign": MinecraftMaterial(
    name: "Cherry Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_hanging_sign.png",
  ),
  "cherry_leaves": MinecraftMaterial(
    name: "Cherry Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_leaves.png",
  ),
  "cherry_log": MinecraftMaterial(
    name: "Cherry Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_log.png",
  ),
  "cherry_planks": MinecraftMaterial(
    name: "Cherry Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_planks.png",
  ),
  "cherry_pressure_plate": MinecraftMaterial(
    name: "Cherry Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_pressure_plate.png",
  ),
  "cherry_sapling": MinecraftMaterial(
    name: "Cherry Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_sapling.png",
  ),
  "cherry_sign": MinecraftMaterial(
    name: "Cherry Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_sign.png",
  ),
  "cherry_slab": MinecraftMaterial(
    name: "Cherry Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_slab.png",
  ),
  "cherry_stairs": MinecraftMaterial(
    name: "Cherry Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_stairs.png",
  ),
  "cherry_trapdoor": MinecraftMaterial(
    name: "Cherry Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_trapdoor.png",
  ),
  "cherry_wood": MinecraftMaterial(
    name: "Cherry Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cherry_wood.png",
  ),
  "chest": MinecraftMaterial(
    name: "Chest",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/chest.png",
  ),
  "chest_minecart": MinecraftMaterial(
    name: "Chest Minecart",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/chest_minecart.png",
  ),
  "chicken": MinecraftMaterial(
    name: "Chicken",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/chicken.png",
  ),
  "chicken_spawn_egg": MinecraftMaterial(
    name: "Chicken Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/chicken_spawn_egg.png",
  ),
  "chipped_anvil": MinecraftMaterial(
    name: "Chipped Anvil",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chipped_anvil.png",
  ),
  "chiseled_bookshelf": MinecraftMaterial(
    name: "Chiseled Bookshelf",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/chiseled_bookshelf.png",
  ),
  "chiseled_copper": MinecraftMaterial(
    name: "Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/chiseled_copper.png",
  ),
  "chiseled_deepslate": MinecraftMaterial(
    name: "Chiseled Deepslate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chiseled_deepslate.png",
  ),
  "chiseled_nether_bricks": MinecraftMaterial(
    name: "Chiseled Nether Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chiseled_nether_bricks.png",
  ),
  "chiseled_polished_blackstone": MinecraftMaterial(
    name: "Chiseled Polished Blackstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chiseled_polished_blackstone.png",
  ),
  "chiseled_quartz_block": MinecraftMaterial(
    name: "Chiseled Quartz Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chiseled_quartz_block.png",
  ),
  "chiseled_red_sandstone": MinecraftMaterial(
    name: "Chiseled Red Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chiseled_red_sandstone.png",
  ),
  "chiseled_resin_bricks": MinecraftMaterial(
    name: "Chiseled Resin Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/chiseled_resin_bricks.png",
  ),
  "chiseled_sandstone": MinecraftMaterial(
    name: "Chiseled Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chiseled_sandstone.png",
  ),
  "chiseled_stone_bricks": MinecraftMaterial(
    name: "Chiseled Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chiseled_stone_bricks.png",
  ),
  "chiseled_tuff": MinecraftMaterial(
    name: "Chiseled Tuff",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/chiseled_tuff.png",
  ),
  "chiseled_tuff_bricks": MinecraftMaterial(
    name: "Chiseled Tuff Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/chiseled_tuff_bricks.png",
  ),
  "chorus_flower": MinecraftMaterial(
    name: "Chorus Flower",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/chorus_flower.png",
  ),
  "chorus_fruit": MinecraftMaterial(
    name: "Chorus Fruit",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/chorus_fruit.png",
  ),
  "chorus_plant": MinecraftMaterial(
    name: "Chorus Plant",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/chorus_plant.png",
  ),
  "clay": MinecraftMaterial(
    name: "Clay",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/clay.png",
  ),
  "clay_ball": MinecraftMaterial(
    name: "Clay Ball",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/clay_ball.png",
  ),
  "clock": MinecraftMaterial(
    name: "Clock",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/clock.png",
  ),
  "closed_eyeblossom": MinecraftMaterial(
    name: "Closed Eyeblossom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/closed_eyeblossom.png",
  ),
  "coal": MinecraftMaterial(
    name: "Coal",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/coal.png",
  ),
  "coal_block": MinecraftMaterial(
    name: "Coal Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/coal_block.png",
  ),
  "coal_ore": MinecraftMaterial(
    name: "Coal Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/coal_ore.png",
  ),
  "coarse_dirt": MinecraftMaterial(
    name: "Coarse Dirt",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/coarse_dirt.png",
  ),
  "coast_armor_trim_smithing_template": MinecraftMaterial(
    name: "Coast Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/coast_armor_trim_smithing_template.png",
  ),
  "cobbled_deepslate": MinecraftMaterial(
    name: "Cobbled Deepslate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobbled_deepslate.png",
  ),
  "cobbled_deepslate_slab": MinecraftMaterial(
    name: "Cobbled Deepslate Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobbled_deepslate_slab.png",
  ),
  "cobbled_deepslate_stairs": MinecraftMaterial(
    name: "Cobbled Deepslate Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobbled_deepslate_stairs.png",
  ),
  "cobbled_deepslate_wall": MinecraftMaterial(
    name: "Cobbled Deepslate Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobbled_deepslate_wall.png",
  ),
  "cobblestone": MinecraftMaterial(
    name: "Cobblestone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobblestone.png",
  ),
  "cobblestone_slab": MinecraftMaterial(
    name: "Cobblestone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobblestone_slab.png",
  ),
  "cobblestone_stairs": MinecraftMaterial(
    name: "Cobblestone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobblestone_stairs.png",
  ),
  "cobblestone_wall": MinecraftMaterial(
    name: "Cobblestone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobblestone_wall.png",
  ),
  "cobweb": MinecraftMaterial(
    name: "Cobweb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cobweb.png",
  ),
  "cocoa_beans": MinecraftMaterial(
    name: "Cocoa Beans",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cocoa_beans.png",
  ),
  "cod": MinecraftMaterial(
    name: "Cod",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cod.png",
  ),
  "cod_bucket": MinecraftMaterial(
    name: "Cod Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cod_bucket.png",
  ),
  "cod_spawn_egg": MinecraftMaterial(
    name: "Cod Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cod_spawn_egg.png",
  ),
  "command_block": MinecraftMaterial(
    name: "Command Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/command_block.png",
  ),
  "command_block_minecart": MinecraftMaterial(
    name: "Command Block Minecart",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/command_block_minecart.png",
  ),
  "comparator": MinecraftMaterial(
    name: "Comparator",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/comparator.png",
  ),
  "compass": MinecraftMaterial(
    name: "Compass",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/compass.png",
  ),
  "composter": MinecraftMaterial(
    name: "Composter",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/composter.png",
  ),
  "conduit": MinecraftMaterial(
    name: "Conduit",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/conduit.png",
  ),
  "cooked_beef": MinecraftMaterial(
    name: "Cooked Beef",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cooked_beef.png",
  ),
  "cooked_chicken": MinecraftMaterial(
    name: "Cooked Chicken",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cooked_chicken.png",
  ),
  "cooked_cod": MinecraftMaterial(
    name: "Cooked Cod",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cooked_cod.png",
  ),
  "cooked_mutton": MinecraftMaterial(
    name: "Cooked Mutton",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cooked_mutton.png",
  ),
  "cooked_porkchop": MinecraftMaterial(
    name: "Cooked Porkchop",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cooked_porkchop.png",
  ),
  "cooked_rabbit": MinecraftMaterial(
    name: "Cooked Rabbit",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cooked_rabbit.png",
  ),
  "cooked_salmon": MinecraftMaterial(
    name: "Cooked Salmon",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cooked_salmon.png",
  ),
  "cookie": MinecraftMaterial(
    name: "Cookie",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/cookie.png",
  ),
  "copper_block": MinecraftMaterial(
    name: "Copper Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/copper_block.png",
  ),
  "copper_bulb": MinecraftMaterial(
    name: "Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_bulb.png",
  ),
  "copper_door": MinecraftMaterial(
    name: "Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_door.png",
  ),
  "copper_grate": MinecraftMaterial(
    name: "Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_grate.png",
  ),
  "copper_ingot": MinecraftMaterial(
    name: "Copper Ingot",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_ingot.png",
  ),
  "copper_ore": MinecraftMaterial(
    name: "Copper Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/copper_ore.png",
  ),
  "copper_trapdoor": MinecraftMaterial(
    name: "Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_trapdoor.png",
  ),
  "copper_chain": MinecraftMaterial(
    name: "Copper Chain",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_chain.png",
  ),
  "copper_lantern": MinecraftMaterial(
    name: "Copper Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_lantern.png",
  ),
  "copper_pickaxe": MinecraftMaterial(
    name: "Copper Pickaxe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_pickaxe.png",
  ),
  "copper_axe": MinecraftMaterial(
    name: "Copper Axe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_axe.png",
  ),
  "copper_shovel": MinecraftMaterial(
    name: "Copper Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_shovel.png",
  ),
  "copper_hoe": MinecraftMaterial(
    name: "Copper Hoe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_hoe.png",
  ),
  "copper_sword": MinecraftMaterial(
    name: "Copper Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_sword.png",
  ),
  "copper_helmet": MinecraftMaterial(
    name: "Copper Helmet",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_helmet.png",
  ),
  "copper_chestplate": MinecraftMaterial(
    name: "Copper Chestplate",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_chestplate.png",
  ),
  "copper_leggings": MinecraftMaterial(
    name: "Copper Leggings",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_leggings.png",
  ),
  "copper_boots": MinecraftMaterial(
    name: "Copper Boots",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_boots.png",
  ),
  "copper_horse_armor": MinecraftMaterial(
    name: "Copper Horse Armor",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_horse_armor.png",
  ),
  "copper_nugget": MinecraftMaterial(
    name: "Copper Nugget",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_nugget.png",
  ),
  "copper_golem_spawn_egg": MinecraftMaterial(
    name: "Copper Golem Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_golem_spawn_egg.png",
  ),
  "cornflower": MinecraftMaterial(
    name: "Cornflower",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/cornflower.png",
  ),
  "cow_spawn_egg": MinecraftMaterial(
    name: "Cow Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cow_spawn_egg.png",
  ),
  "cracked_deepslate_bricks": MinecraftMaterial(
    name: "Cracked Deepslate Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cracked_deepslate_bricks.png",
  ),
  "cracked_deepslate_tiles": MinecraftMaterial(
    name: "Cracked Deepslate Tiles",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cracked_deepslate_tiles.png",
  ),
  "cracked_nether_bricks": MinecraftMaterial(
    name: "Cracked Nether Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cracked_nether_bricks.png",
  ),
  "cracked_polished_blackstone_bricks": MinecraftMaterial(
    name: "Cracked Polished Blackstone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cracked_polished_blackstone_bricks.png",
  ),
  "cracked_stone_bricks": MinecraftMaterial(
    name: "Cracked Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cracked_stone_bricks.png",
  ),
  "crafter": MinecraftMaterial(
    name: "Crafter",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/crafter.png",
  ),
  "crafting_table": MinecraftMaterial(
    name: "Crafting Table",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/crafting_table.png",
  ),
  "creaking_heart": MinecraftMaterial(
    name: "Creaking Heart",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/creaking_heart.png",
  ),
  "creaking_spawn_egg": MinecraftMaterial(
    name: "Creaking Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/creaking_spawn_egg.png",
  ),
  "creeper_banner_pattern": MinecraftMaterial(
    name: "Creeper Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/creeper_banner_pattern.png",
  ),
  "creeper_head": MinecraftMaterial(
    name: "Creeper Head",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/creeper_head.png",
  ),
  "creeper_spawn_egg": MinecraftMaterial(
    name: "Creeper Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/creeper_spawn_egg.png",
  ),
  "crimson_button": MinecraftMaterial(
    name: "Crimson Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/crimson_button.png",
  ),
  "crimson_door": MinecraftMaterial(
    name: "Crimson Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_door.png",
  ),
  "crimson_fence": MinecraftMaterial(
    name: "Crimson Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_fence.png",
  ),
  "crimson_fence_gate": MinecraftMaterial(
    name: "Crimson Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_fence_gate.png",
  ),
  "crimson_fungus": MinecraftMaterial(
    name: "Crimson Fungus",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/crimson_fungus.png",
  ),
  "crimson_hanging_sign": MinecraftMaterial(
    name: "Crimson Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/crimson_hanging_sign.png",
  ),
  "crimson_hyphae": MinecraftMaterial(
    name: "Crimson Hyphae",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_hyphae.png",
  ),
  "crimson_nylium": MinecraftMaterial(
    name: "Crimson Nylium",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_nylium.png",
  ),
  "crimson_planks": MinecraftMaterial(
    name: "Crimson Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_planks.png",
  ),
  "crimson_pressure_plate": MinecraftMaterial(
    name: "Crimson Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_pressure_plate.png",
  ),
  "crimson_roots": MinecraftMaterial(
    name: "Crimson Roots",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/crimson_roots.png",
  ),
  "crimson_sign": MinecraftMaterial(
    name: "Crimson Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_sign.png",
  ),
  "crimson_slab": MinecraftMaterial(
    name: "Crimson Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_slab.png",
  ),
  "crimson_stairs": MinecraftMaterial(
    name: "Crimson Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_stairs.png",
  ),
  "crimson_stem": MinecraftMaterial(
    name: "Crimson Stem",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_stem.png",
  ),
  "crimson_trapdoor": MinecraftMaterial(
    name: "Crimson Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_trapdoor.png",
  ),
  "crossbow": MinecraftMaterial(
    name: "Crossbow",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/crossbow.png",
  ),
  "crying_obsidian": MinecraftMaterial(
    name: "Crying Obsidian",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crying_obsidian.png",
  ),
  "cut_copper": MinecraftMaterial(
    name: "Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_copper.png",
  ),
  "cut_copper_slab": MinecraftMaterial(
    name: "Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_copper_slab.png",
  ),
  "cut_copper_stairs": MinecraftMaterial(
    name: "Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_copper_stairs.png",
  ),
  "cut_red_sandstone": MinecraftMaterial(
    name: "Cut Red Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_red_sandstone.png",
  ),
  "cut_red_sandstone_slab": MinecraftMaterial(
    name: "Cut Red Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_red_sandstone_slab.png",
  ),
  "cut_sandstone": MinecraftMaterial(
    name: "Cut Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_sandstone.png",
  ),
  "cut_sandstone_slab": MinecraftMaterial(
    name: "Cut Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_sandstone_slab.png",
  ),
  "cyan_banner": MinecraftMaterial(
    name: "Cyan Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/cyan_banner.png",
  ),
  "cyan_bed": MinecraftMaterial(
    name: "Cyan Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/cyan_bed.png",
  ),
  "cyan_bundle": MinecraftMaterial(
    name: "Cyan Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cyan_bundle.png",
  ),
  "cyan_candle": MinecraftMaterial(
    name: "Cyan Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/cyan_candle.png",
  ),
  "cyan_carpet": MinecraftMaterial(
    name: "Cyan Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/cyan_carpet.png",
  ),
  "cyan_concrete": MinecraftMaterial(
    name: "Cyan Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_concrete.png",
  ),
  "cyan_concrete_powder": MinecraftMaterial(
    name: "Cyan Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_concrete_powder.png",
  ),
  "cyan_dye": MinecraftMaterial(
    name: "Cyan Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cyan_dye.png",
  ),
  "cyan_glazed_terracotta": MinecraftMaterial(
    name: "Cyan Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_glazed_terracotta.png",
  ),
  "cyan_harness": MinecraftMaterial(
    name: "Cyan Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cyan_harness.png",
  ),
  "cyan_shulker_box": MinecraftMaterial(
    name: "Cyan Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_shulker_box.png",
  ),
  "cyan_stained_glass": MinecraftMaterial(
    name: "Cyan Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_stained_glass.png",
  ),
  "cyan_stained_glass_pane": MinecraftMaterial(
    name: "Cyan Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_stained_glass_pane.png",
  ),
  "cyan_terracotta": MinecraftMaterial(
    name: "Cyan Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_terracotta.png",
  ),
  "cyan_wool": MinecraftMaterial(
    name: "Cyan Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/cyan_wool.png",
  ),
  "damaged_anvil": MinecraftMaterial(
    name: "Damaged Anvil",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/damaged_anvil.png",
  ),
  "dandelion": MinecraftMaterial(
    name: "Dandelion",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/dandelion.png",
  ),
  "danger_pottery_sherd": MinecraftMaterial(
    name: "Danger Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/danger_pottery_sherd.png",
  ),
  "dark_oak_boat": MinecraftMaterial(
    name: "Dark Oak Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/dark_oak_boat.png",
  ),
  "dark_oak_button": MinecraftMaterial(
    name: "Dark Oak Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/dark_oak_button.png",
  ),
  "dark_oak_chest_boat": MinecraftMaterial(
    name: "Dark Oak Chest Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/dark_oak_chest_boat.png",
  ),
  "dark_oak_door": MinecraftMaterial(
    name: "Dark Oak Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_door.png",
  ),
  "dark_oak_fence": MinecraftMaterial(
    name: "Dark Oak Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_fence.png",
  ),
  "dark_oak_fence_gate": MinecraftMaterial(
    name: "Dark Oak Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_fence_gate.png",
  ),
  "dark_oak_hanging_sign": MinecraftMaterial(
    name: "Dark Oak Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/dark_oak_hanging_sign.png",
  ),
  "dark_oak_leaves": MinecraftMaterial(
    name: "Dark Oak Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_leaves.png",
  ),
  "dark_oak_log": MinecraftMaterial(
    name: "Dark Oak Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_log.png",
  ),
  "dark_oak_planks": MinecraftMaterial(
    name: "Dark Oak Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_planks.png",
  ),
  "dark_oak_pressure_plate": MinecraftMaterial(
    name: "Dark Oak Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_pressure_plate.png",
  ),
  "dark_oak_sapling": MinecraftMaterial(
    name: "Dark Oak Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/dark_oak_sapling.png",
  ),
  "dark_oak_sign": MinecraftMaterial(
    name: "Dark Oak Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_sign.png",
  ),
  "dark_oak_slab": MinecraftMaterial(
    name: "Dark Oak Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_slab.png",
  ),
  "dark_oak_stairs": MinecraftMaterial(
    name: "Dark Oak Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_stairs.png",
  ),
  "dark_oak_trapdoor": MinecraftMaterial(
    name: "Dark Oak Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_trapdoor.png",
  ),
  "dark_oak_wood": MinecraftMaterial(
    name: "Dark Oak Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_wood.png",
  ),
  "dark_prismarine": MinecraftMaterial(
    name: "Dark Prismarine",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dark_prismarine.png",
  ),
  "dark_prismarine_slab": MinecraftMaterial(
    name: "Dark Prismarine Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dark_prismarine_slab.png",
  ),
  "dark_prismarine_stairs": MinecraftMaterial(
    name: "Dark Prismarine Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dark_prismarine_stairs.png",
  ),
  "daylight_detector": MinecraftMaterial(
    name: "Daylight Detector",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/daylight_detector.png",
  ),
  "dead_brain_coral": MinecraftMaterial(
    name: "Dead Brain Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_brain_coral.png",
  ),
  "dead_brain_coral_block": MinecraftMaterial(
    name: "Dead Brain Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_brain_coral_block.png",
  ),
  "dead_brain_coral_fan": MinecraftMaterial(
    name: "Dead Brain Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_brain_coral_fan.png",
  ),
  "dead_bubble_coral": MinecraftMaterial(
    name: "Dead Bubble Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_bubble_coral.png",
  ),
  "dead_bubble_coral_block": MinecraftMaterial(
    name: "Dead Bubble Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_bubble_coral_block.png",
  ),
  "dead_bubble_coral_fan": MinecraftMaterial(
    name: "Dead Bubble Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_bubble_coral_fan.png",
  ),
  "dead_bush": MinecraftMaterial(
    name: "Dead Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dead_bush.png",
  ),
  "dead_fire_coral": MinecraftMaterial(
    name: "Dead Fire Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_fire_coral.png",
  ),
  "dead_fire_coral_block": MinecraftMaterial(
    name: "Dead Fire Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_fire_coral_block.png",
  ),
  "dead_fire_coral_fan": MinecraftMaterial(
    name: "Dead Fire Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_fire_coral_fan.png",
  ),
  "dead_horn_coral": MinecraftMaterial(
    name: "Dead Horn Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_horn_coral.png",
  ),
  "dead_horn_coral_block": MinecraftMaterial(
    name: "Dead Horn Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_horn_coral_block.png",
  ),
  "dead_horn_coral_fan": MinecraftMaterial(
    name: "Dead Horn Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_horn_coral_fan.png",
  ),
  "dead_tube_coral": MinecraftMaterial(
    name: "Dead Tube Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_tube_coral.png",
  ),
  "dead_tube_coral_block": MinecraftMaterial(
    name: "Dead Tube Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_tube_coral_block.png",
  ),
  "dead_tube_coral_fan": MinecraftMaterial(
    name: "Dead Tube Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_tube_coral_fan.png",
  ),
  "debug_stick": MinecraftMaterial(
    name: "Debug Stick",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/debug_stick.png",
  ),
  "decorated_pot": MinecraftMaterial(
    name: "Decorated Pot",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/decorated_pot.png",
  ),
  "deepslate": MinecraftMaterial(
    name: "Deepslate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate.png",
  ),
  "deepslate_brick_slab": MinecraftMaterial(
    name: "Deepslate Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_brick_slab.png",
  ),
  "deepslate_brick_stairs": MinecraftMaterial(
    name: "Deepslate Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_brick_stairs.png",
  ),
  "deepslate_brick_wall": MinecraftMaterial(
    name: "Deepslate Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_brick_wall.png",
  ),
  "deepslate_bricks": MinecraftMaterial(
    name: "Deepslate Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_bricks.png",
  ),
  "deepslate_coal_ore": MinecraftMaterial(
    name: "Deepslate Coal Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_coal_ore.png",
  ),
  "deepslate_copper_ore": MinecraftMaterial(
    name: "Deepslate Copper Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_copper_ore.png",
  ),
  "deepslate_diamond_ore": MinecraftMaterial(
    name: "Deepslate Diamond Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_diamond_ore.png",
  ),
  "deepslate_emerald_ore": MinecraftMaterial(
    name: "Deepslate Emerald Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_emerald_ore.png",
  ),
  "deepslate_gold_ore": MinecraftMaterial(
    name: "Deepslate Gold Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_gold_ore.png",
  ),
  "deepslate_iron_ore": MinecraftMaterial(
    name: "Deepslate Iron Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_iron_ore.png",
  ),
  "deepslate_lapis_ore": MinecraftMaterial(
    name: "Deepslate Lapis Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_lapis_ore.png",
  ),
  "deepslate_redstone_ore": MinecraftMaterial(
    name: "Deepslate Redstone Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/deepslate_redstone_ore.png",
  ),
  "deepslate_tile_slab": MinecraftMaterial(
    name: "Deepslate Tile Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_tile_slab.png",
  ),
  "deepslate_tile_stairs": MinecraftMaterial(
    name: "Deepslate Tile Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_tile_stairs.png",
  ),
  "deepslate_tile_wall": MinecraftMaterial(
    name: "Deepslate Tile Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_tile_wall.png",
  ),
  "deepslate_tiles": MinecraftMaterial(
    name: "Deepslate Tiles",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_tiles.png",
  ),
  "detector_rail": MinecraftMaterial(
    name: "Detector Rail",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/detector_rail.png",
  ),
  "diamond": MinecraftMaterial(
    name: "Diamond",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/diamond.png",
  ),
  "diamond_axe": MinecraftMaterial(
    name: "Diamond Axe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/diamond_axe.png",
  ),
  "diamond_block": MinecraftMaterial(
    name: "Diamond Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/diamond_block.png",
  ),
  "diamond_boots": MinecraftMaterial(
    name: "Diamond Boots",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/diamond_boots.png",
  ),
  "diamond_chestplate": MinecraftMaterial(
    name: "Diamond Chestplate",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/diamond_chestplate.png",
  ),
  "diamond_helmet": MinecraftMaterial(
    name: "Diamond Helmet",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/diamond_helmet.png",
  ),
  "diamond_hoe": MinecraftMaterial(
    name: "Diamond Hoe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/diamond_hoe.png",
  ),
  "diamond_horse_armor": MinecraftMaterial(
    name: "Diamond Horse Armor",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/diamond_horse_armor.png",
  ),
  "diamond_leggings": MinecraftMaterial(
    name: "Diamond Leggings",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/diamond_leggings.png",
  ),
  "diamond_ore": MinecraftMaterial(
    name: "Diamond Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/diamond_ore.png",
  ),
  "diamond_pickaxe": MinecraftMaterial(
    name: "Diamond Pickaxe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/diamond_pickaxe.png",
  ),
  "diamond_shovel": MinecraftMaterial(
    name: "Diamond Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/diamond_shovel.png",
  ),
  "diamond_sword": MinecraftMaterial(
    name: "Diamond Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/diamond_sword.png",
  ),
  "diorite": MinecraftMaterial(
    name: "Diorite",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/diorite.png",
  ),
  "diorite_slab": MinecraftMaterial(
    name: "Diorite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/diorite_slab.png",
  ),
  "diorite_stairs": MinecraftMaterial(
    name: "Diorite Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/diorite_stairs.png",
  ),
  "diorite_wall": MinecraftMaterial(
    name: "Diorite Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/diorite_wall.png",
  ),
  "dirt": MinecraftMaterial(
    name: "Dirt",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dirt.png",
  ),
  "dirt_path": MinecraftMaterial(
    name: "Dirt Path",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dirt_path.png",
  ),
  "disc_fragment_5": MinecraftMaterial(
    name: "Disc Fragment 5",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/disc_fragment_5.png",
  ),
  "dispenser": MinecraftMaterial(
    name: "Dispenser",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dispenser.png",
  ),
  "dolphin_spawn_egg": MinecraftMaterial(
    name: "Dolphin Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/dolphin_spawn_egg.png",
  ),
  "donkey_spawn_egg": MinecraftMaterial(
    name: "Donkey Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/donkey_spawn_egg.png",
  ),
  "dragon_breath": MinecraftMaterial(
    name: "Dragon Breath",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/dragon_breath.png",
  ),
  "dragon_egg": MinecraftMaterial(
    name: "Dragon Egg",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dragon_egg.png",
  ),
  "dragon_head": MinecraftMaterial(
    name: "Dragon Head",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/dragon_head.png",
  ),
  "dried_ghast": MinecraftMaterial(
    name: "Dried Ghast",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/dried_ghast.png",
  ),
  "dried_kelp": MinecraftMaterial(
    name: "Dried Kelp",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/dried_kelp.png",
  ),
  "dried_kelp_block": MinecraftMaterial(
    name: "Dried Kelp Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/dried_kelp_block.png",
  ),
  "dripstone_block": MinecraftMaterial(
    name: "Dripstone Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dripstone_block.png",
  ),
  "dropper": MinecraftMaterial(
    name: "Dropper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dropper.png",
  ),
  "drowned_spawn_egg": MinecraftMaterial(
    name: "Drowned Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/drowned_spawn_egg.png",
  ),
  "dune_armor_trim_smithing_template": MinecraftMaterial(
    name: "Dune Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/dune_armor_trim_smithing_template.png",
  ),
  "echo_shard": MinecraftMaterial(
    name: "Echo Shard",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/echo_shard.png",
  ),
  "egg": MinecraftMaterial(
    name: "Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/egg.png",
  ),
  "elder_guardian_spawn_egg": MinecraftMaterial(
    name: "Elder Guardian Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/elder_guardian_spawn_egg.png",
  ),
  "elytra": MinecraftMaterial(
    name: "Elytra",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/elytra.png",
  ),
  "emerald": MinecraftMaterial(
    name: "Emerald",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/emerald.png",
  ),
  "emerald_block": MinecraftMaterial(
    name: "Emerald Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/emerald_block.png",
  ),
  "emerald_ore": MinecraftMaterial(
    name: "Emerald Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/emerald_ore.png",
  ),
  "enchanted_book": MinecraftMaterial(
    name: "Enchanted Book",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/enchanted_book.png",
  ),
  "enchanted_golden_apple": MinecraftMaterial(
    name: "Enchanted Golden Apple",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/enchanted_golden_apple.png",
  ),
  "enchanting_table": MinecraftMaterial(
    name: "Enchanting Table",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/enchanting_table.png",
  ),
  "end_crystal": MinecraftMaterial(
    name: "End Crystal",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/end_crystal.png",
  ),
  "end_portal_frame": MinecraftMaterial(
    name: "End Portal Frame",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/end_portal_frame.png",
  ),
  "end_rod": MinecraftMaterial(
    name: "End Rod",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/end_rod.png",
  ),
  "end_stone": MinecraftMaterial(
    name: "End Stone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/end_stone.png",
  ),
  "end_stone_brick_slab": MinecraftMaterial(
    name: "End Stone Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/end_stone_brick_slab.png",
  ),
  "end_stone_brick_stairs": MinecraftMaterial(
    name: "End Stone Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/end_stone_brick_stairs.png",
  ),
  "end_stone_brick_wall": MinecraftMaterial(
    name: "End Stone Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/end_stone_brick_wall.png",
  ),
  "end_stone_bricks": MinecraftMaterial(
    name: "End Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/end_stone_bricks.png",
  ),
  "ender_chest": MinecraftMaterial(
    name: "Ender Chest",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/ender_chest.png",
  ),
  "ender_dragon_spawn_egg": MinecraftMaterial(
    name: "Ender Dragon Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ender_dragon_spawn_egg.png",
  ),
  "ender_eye": MinecraftMaterial(
    name: "Ender Eye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ender_eye.png",
  ),
  "ender_pearl": MinecraftMaterial(
    name: "Ender Pearl",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ender_pearl.png",
  ),
  "enderman_spawn_egg": MinecraftMaterial(
    name: "Enderman Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/enderman_spawn_egg.png",
  ),
  "endermite_spawn_egg": MinecraftMaterial(
    name: "Endermite Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/endermite_spawn_egg.png",
  ),
  "evoker_spawn_egg": MinecraftMaterial(
    name: "Evoker Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/evoker_spawn_egg.png",
  ),
  "experience_bottle": MinecraftMaterial(
    name: "Experience Bottle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/experience_bottle.png",
  ),
  "explorer_pottery_sherd": MinecraftMaterial(
    name: "Explorer Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/explorer_pottery_sherd.png",
  ),
  "exposed_chiseled_copper": MinecraftMaterial(
    name: "Exposed Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_chiseled_copper.png",
  ),
  "exposed_copper": MinecraftMaterial(
    name: "Exposed Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/exposed_copper.png",
  ),
  "exposed_copper_bulb": MinecraftMaterial(
    name: "Exposed Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_bulb.png",
  ),
  "exposed_copper_door": MinecraftMaterial(
    name: "Exposed Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_door.png",
  ),
  "exposed_copper_grate": MinecraftMaterial(
    name: "Exposed Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_grate.png",
  ),
  "exposed_copper_trapdoor": MinecraftMaterial(
    name: "Exposed Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_trapdoor.png",
  ),
  "exposed_copper_chain": MinecraftMaterial(
    name: "Exposed Copper Chain",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_chain.png",
  ),
  "exposed_copper_lantern": MinecraftMaterial(
    name: "Exposed Copper Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_lantern.png",
  ),
  "exposed_cut_copper": MinecraftMaterial(
    name: "Exposed Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/exposed_cut_copper.png",
  ),
  "exposed_cut_copper_slab": MinecraftMaterial(
    name: "Exposed Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/exposed_cut_copper_slab.png",
  ),
  "exposed_cut_copper_stairs": MinecraftMaterial(
    name: "Exposed Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/exposed_cut_copper_stairs.png",
  ),
  "eye_armor_trim_smithing_template": MinecraftMaterial(
    name: "Eye Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/eye_armor_trim_smithing_template.png",
  ),
  "farmland": MinecraftMaterial(
    name: "Farmland",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/farmland.png",
  ),
  "feather": MinecraftMaterial(
    name: "Feather",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/feather.png",
  ),
  "fermented_spider_eye": MinecraftMaterial(
    name: "Fermented Spider Eye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/fermented_spider_eye.png",
  ),
  "fern": MinecraftMaterial(
    name: "Fern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/fern.png",
  ),
  "field_masoned_banner_pattern": MinecraftMaterial(
    name: "Field Masoned Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/field_masoned_banner_pattern.png",
  ),
  "filled_map": MinecraftMaterial(
    name: "Filled Map",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/filled_map.png",
  ),
  "fire_charge": MinecraftMaterial(
    name: "Fire Charge",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/fire_charge.png",
  ),
  "fire_coral": MinecraftMaterial(
    name: "Fire Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/fire_coral.png",
  ),
  "fire_coral_block": MinecraftMaterial(
    name: "Fire Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/fire_coral_block.png",
  ),
  "fire_coral_fan": MinecraftMaterial(
    name: "Fire Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/fire_coral_fan.png",
  ),
  "firefly_bush": MinecraftMaterial(
    name: "Firefly Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/firefly_bush.png",
  ),
  "firework_rocket": MinecraftMaterial(
    name: "Firework Rocket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/firework_rocket.png",
  ),
  "firework_star": MinecraftMaterial(
    name: "Firework Star",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/firework_star.png",
  ),
  "fishing_rod": MinecraftMaterial(
    name: "Fishing Rod",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/fishing_rod.png",
  ),
  "fletching_table": MinecraftMaterial(
    name: "Fletching Table",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/fletching_table.png",
  ),
  "flint": MinecraftMaterial(
    name: "Flint",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/flint.png",
  ),
  "flint_and_steel": MinecraftMaterial(
    name: "Flint And Steel",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/flint_and_steel.png",
  ),
  "flow_armor_trim_smithing_template": MinecraftMaterial(
    name: "Flow Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/flow_armor_trim_smithing_template.png",
  ),
  "flow_banner_pattern": MinecraftMaterial(
    name: "Flow Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/flow_banner_pattern.png",
  ),
  "flow_pottery_sherd": MinecraftMaterial(
    name: "Flow Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/flow_pottery_sherd.png",
  ),
  "flower_banner_pattern": MinecraftMaterial(
    name: "Flower Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/flower_banner_pattern.png",
  ),
  "flower_pot": MinecraftMaterial(
    name: "Flower Pot",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/flower_pot.png",
  ),
  "flowering_azalea": MinecraftMaterial(
    name: "Flowering Azalea",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/flowering_azalea.png",
  ),
  "flowering_azalea_leaves": MinecraftMaterial(
    name: "Flowering Azalea Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/flowering_azalea_leaves.png",
  ),
  "fox_spawn_egg": MinecraftMaterial(
    name: "Fox Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/fox_spawn_egg.png",
  ),
  "friend_pottery_sherd": MinecraftMaterial(
    name: "Friend Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/friend_pottery_sherd.png",
  ),
  "frog_spawn_egg": MinecraftMaterial(
    name: "Frog Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/frog_spawn_egg.png",
  ),
  "frogspawn": MinecraftMaterial(
    name: "Frogspawn",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/frogspawn.png",
  ),
  "furnace": MinecraftMaterial(
    name: "Furnace",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/furnace.png",
  ),
  "furnace_minecart": MinecraftMaterial(
    name: "Furnace Minecart",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/furnace_minecart.png",
  ),
  "ghast_spawn_egg": MinecraftMaterial(
    name: "Ghast Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ghast_spawn_egg.png",
  ),
  "ghast_tear": MinecraftMaterial(
    name: "Ghast Tear",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ghast_tear.png",
  ),
  "gilded_blackstone": MinecraftMaterial(
    name: "Gilded Blackstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gilded_blackstone.png",
  ),
  "glass": MinecraftMaterial(
    name: "Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/glass.png",
  ),
  "glass_bottle": MinecraftMaterial(
    name: "Glass Bottle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/glass_bottle.png",
  ),
  "glass_pane": MinecraftMaterial(
    name: "Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/glass_pane.png",
  ),
  "glistering_melon_slice": MinecraftMaterial(
    name: "Glistering Melon Slice",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/glistering_melon_slice.png",
  ),
  "globe_banner_pattern": MinecraftMaterial(
    name: "Globe Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/globe_banner_pattern.png",
  ),
  "glow_berries": MinecraftMaterial(
    name: "Glow Berries",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/glow_berries.png",
  ),
  "glow_ink_sac": MinecraftMaterial(
    name: "Glow Ink Sac",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/glow_ink_sac.png",
  ),
  "glow_item_frame": MinecraftMaterial(
    name: "Glow Item Frame",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/glow_item_frame.png",
  ),
  "glow_lichen": MinecraftMaterial(
    name: "Glow Lichen",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/glow_lichen.png",
  ),
  "glow_squid_spawn_egg": MinecraftMaterial(
    name: "Glow Squid Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/glow_squid_spawn_egg.png",
  ),
  "glowstone": MinecraftMaterial(
    name: "Glowstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/glowstone.png",
  ),
  "glowstone_dust": MinecraftMaterial(
    name: "Glowstone Dust",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/glowstone_dust.png",
  ),
  "goat_horn": MinecraftMaterial(
    name: "Goat Horn",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/goat_horn.png",
  ),
  "goat_spawn_egg": MinecraftMaterial(
    name: "Goat Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/goat_spawn_egg.png",
  ),
  "gold_block": MinecraftMaterial(
    name: "Gold Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gold_block.png",
  ),
  "gold_ingot": MinecraftMaterial(
    name: "Gold Ingot",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gold_ingot.png",
  ),
  "gold_nugget": MinecraftMaterial(
    name: "Gold Nugget",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gold_nugget.png",
  ),
  "gold_ore": MinecraftMaterial(
    name: "Gold Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/gold_ore.png",
  ),
  "golden_apple": MinecraftMaterial(
    name: "Golden Apple",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/golden_apple.png",
  ),
  "golden_axe": MinecraftMaterial(
    name: "Golden Axe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/golden_axe.png",
  ),
  "golden_boots": MinecraftMaterial(
    name: "Golden Boots",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/golden_boots.png",
  ),
  "golden_carrot": MinecraftMaterial(
    name: "Golden Carrot",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/golden_carrot.png",
  ),
  "golden_chestplate": MinecraftMaterial(
    name: "Golden Chestplate",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/golden_chestplate.png",
  ),
  "golden_helmet": MinecraftMaterial(
    name: "Golden Helmet",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/golden_helmet.png",
  ),
  "golden_hoe": MinecraftMaterial(
    name: "Golden Hoe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/golden_hoe.png",
  ),
  "golden_horse_armor": MinecraftMaterial(
    name: "Golden Horse Armor",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/golden_horse_armor.png",
  ),
  "golden_leggings": MinecraftMaterial(
    name: "Golden Leggings",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/golden_leggings.png",
  ),
  "golden_pickaxe": MinecraftMaterial(
    name: "Golden Pickaxe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/golden_pickaxe.png",
  ),
  "golden_shovel": MinecraftMaterial(
    name: "Golden Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/golden_shovel.png",
  ),
  "golden_sword": MinecraftMaterial(
    name: "Golden Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/golden_sword.png",
  ),
  "granite": MinecraftMaterial(
    name: "Granite",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/granite.png",
  ),
  "granite_slab": MinecraftMaterial(
    name: "Granite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/granite_slab.png",
  ),
  "granite_stairs": MinecraftMaterial(
    name: "Granite Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/granite_stairs.png",
  ),
  "granite_wall": MinecraftMaterial(
    name: "Granite Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/granite_wall.png",
  ),
  "grass_block": MinecraftMaterial(
    name: "Grass Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/grass_block.png",
  ),
  "gravel": MinecraftMaterial(
    name: "Gravel",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gravel.png",
  ),
  "gray_banner": MinecraftMaterial(
    name: "Gray Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/gray_banner.png",
  ),
  "gray_bed": MinecraftMaterial(
    name: "Gray Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/gray_bed.png",
  ),
  "gray_bundle": MinecraftMaterial(
    name: "Gray Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gray_bundle.png",
  ),
  "gray_candle": MinecraftMaterial(
    name: "Gray Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/gray_candle.png",
  ),
  "gray_carpet": MinecraftMaterial(
    name: "Gray Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/gray_carpet.png",
  ),
  "gray_concrete": MinecraftMaterial(
    name: "Gray Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_concrete.png",
  ),
  "gray_concrete_powder": MinecraftMaterial(
    name: "Gray Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_concrete_powder.png",
  ),
  "gray_dye": MinecraftMaterial(
    name: "Gray Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gray_dye.png",
  ),
  "gray_glazed_terracotta": MinecraftMaterial(
    name: "Gray Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_glazed_terracotta.png",
  ),
  "gray_harness": MinecraftMaterial(
    name: "Gray Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gray_harness.png",
  ),
  "gray_shulker_box": MinecraftMaterial(
    name: "Gray Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_shulker_box.png",
  ),
  "gray_stained_glass": MinecraftMaterial(
    name: "Gray Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_stained_glass.png",
  ),
  "gray_stained_glass_pane": MinecraftMaterial(
    name: "Gray Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_stained_glass_pane.png",
  ),
  "gray_terracotta": MinecraftMaterial(
    name: "Gray Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_terracotta.png",
  ),
  "gray_wool": MinecraftMaterial(
    name: "Gray Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/gray_wool.png",
  ),
  "green_banner": MinecraftMaterial(
    name: "Green Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/green_banner.png",
  ),
  "green_bed": MinecraftMaterial(
    name: "Green Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/green_bed.png",
  ),
  "green_bundle": MinecraftMaterial(
    name: "Green Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/green_bundle.png",
  ),
  "green_candle": MinecraftMaterial(
    name: "Green Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/green_candle.png",
  ),
  "green_carpet": MinecraftMaterial(
    name: "Green Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/green_carpet.png",
  ),
  "green_concrete": MinecraftMaterial(
    name: "Green Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_concrete.png",
  ),
  "green_concrete_powder": MinecraftMaterial(
    name: "Green Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_concrete_powder.png",
  ),
  "green_dye": MinecraftMaterial(
    name: "Green Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/green_dye.png",
  ),
  "green_glazed_terracotta": MinecraftMaterial(
    name: "Green Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_glazed_terracotta.png",
  ),
  "green_harness": MinecraftMaterial(
    name: "Green Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/green_harness.png",
  ),
  "green_shulker_box": MinecraftMaterial(
    name: "Green Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_shulker_box.png",
  ),
  "green_stained_glass": MinecraftMaterial(
    name: "Green Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_stained_glass.png",
  ),
  "green_stained_glass_pane": MinecraftMaterial(
    name: "Green Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_stained_glass_pane.png",
  ),
  "green_terracotta": MinecraftMaterial(
    name: "Green Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_terracotta.png",
  ),
  "green_wool": MinecraftMaterial(
    name: "Green Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/green_wool.png",
  ),
  "grindstone": MinecraftMaterial(
    name: "Grindstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/grindstone.png",
  ),
  "guardian_spawn_egg": MinecraftMaterial(
    name: "Guardian Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/guardian_spawn_egg.png",
  ),
  "gunpowder": MinecraftMaterial(
    name: "Gunpowder",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gunpowder.png",
  ),
  "guster_banner_pattern": MinecraftMaterial(
    name: "Guster Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/guster_banner_pattern.png",
  ),
  "guster_pottery_sherd": MinecraftMaterial(
    name: "Guster Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/guster_pottery_sherd.png",
  ),
  "hanging_roots": MinecraftMaterial(
    name: "Hanging Roots",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/hanging_roots.png",
  ),
  "happy_ghast_spawn_egg": MinecraftMaterial(
    name: "Happy Ghast Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/happy_ghast_spawn_egg.png",
  ),
  "hay_block": MinecraftMaterial(
    name: "Hay Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/hay_block.png",
  ),
  "heart_of_the_sea": MinecraftMaterial(
    name: "Heart Of The Sea",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/heart_of_the_sea.png",
  ),
  "heart_pottery_sherd": MinecraftMaterial(
    name: "Heart Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/heart_pottery_sherd.png",
  ),
  "heartbreak_pottery_sherd": MinecraftMaterial(
    name: "Heartbreak Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/heartbreak_pottery_sherd.png",
  ),
  "heavy_core": MinecraftMaterial(
    name: "Heavy Core",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/heavy_core.png",
  ),
  "heavy_weighted_pressure_plate": MinecraftMaterial(
    name: "Heavy Weighted Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/heavy_weighted_pressure_plate.png",
  ),
  "hoglin_spawn_egg": MinecraftMaterial(
    name: "Hoglin Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/hoglin_spawn_egg.png",
  ),
  "honey_block": MinecraftMaterial(
    name: "Honey Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/honey_block.png",
  ),
  "honey_bottle": MinecraftMaterial(
    name: "Honey Bottle",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/honey_bottle.png",
  ),
  "honeycomb": MinecraftMaterial(
    name: "Honeycomb",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/honeycomb.png",
  ),
  "honeycomb_block": MinecraftMaterial(
    name: "Honeycomb Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/honeycomb_block.png",
  ),
  "hopper": MinecraftMaterial(
    name: "Hopper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/hopper.png",
  ),
  "hopper_minecart": MinecraftMaterial(
    name: "Hopper Minecart",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/hopper_minecart.png",
  ),
  "horn_coral": MinecraftMaterial(
    name: "Horn Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/horn_coral.png",
  ),
  "horn_coral_block": MinecraftMaterial(
    name: "Horn Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/horn_coral_block.png",
  ),
  "horn_coral_fan": MinecraftMaterial(
    name: "Horn Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/horn_coral_fan.png",
  ),
  "horse_spawn_egg": MinecraftMaterial(
    name: "Horse Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/horse_spawn_egg.png",
  ),
  "host_armor_trim_smithing_template": MinecraftMaterial(
    name: "Host Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/host_armor_trim_smithing_template.png",
  ),
  "howl_pottery_sherd": MinecraftMaterial(
    name: "Howl Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/howl_pottery_sherd.png",
  ),
  "husk_spawn_egg": MinecraftMaterial(
    name: "Husk Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/husk_spawn_egg.png",
  ),
  "ice": MinecraftMaterial(
    name: "Ice",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/ice.png",
  ),
  "infested_chiseled_stone_bricks": MinecraftMaterial(
    name: "Infested Chiseled Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/infested_chiseled_stone_bricks.png",
  ),
  "infested_cobblestone": MinecraftMaterial(
    name: "Infested Cobblestone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/infested_cobblestone.png",
  ),
  "infested_cracked_stone_bricks": MinecraftMaterial(
    name: "Infested Cracked Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/infested_cracked_stone_bricks.png",
  ),
  "infested_deepslate": MinecraftMaterial(
    name: "Infested Deepslate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/infested_deepslate.png",
  ),
  "infested_mossy_stone_bricks": MinecraftMaterial(
    name: "Infested Mossy Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/infested_mossy_stone_bricks.png",
  ),
  "infested_stone": MinecraftMaterial(
    name: "Infested Stone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/infested_stone.png",
  ),
  "infested_stone_bricks": MinecraftMaterial(
    name: "Infested Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/infested_stone_bricks.png",
  ),
  "ink_sac": MinecraftMaterial(
    name: "Ink Sac",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ink_sac.png",
  ),
  "iron_axe": MinecraftMaterial(
    name: "Iron Axe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/iron_axe.png",
  ),
  "iron_bars": MinecraftMaterial(
    name: "Iron Bars",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/iron_bars.png",
  ),
  "iron_block": MinecraftMaterial(
    name: "Iron Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/iron_block.png",
  ),
  "iron_boots": MinecraftMaterial(
    name: "Iron Boots",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/iron_boots.png",
  ),
  "iron_chestplate": MinecraftMaterial(
    name: "Iron Chestplate",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/iron_chestplate.png",
  ),
  "iron_door": MinecraftMaterial(
    name: "Iron Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/iron_door.png",
  ),
  "iron_golem_spawn_egg": MinecraftMaterial(
    name: "Iron Golem Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/iron_golem_spawn_egg.png",
  ),
  "iron_helmet": MinecraftMaterial(
    name: "Iron Helmet",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/iron_helmet.png",
  ),
  "iron_hoe": MinecraftMaterial(
    name: "Iron Hoe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/iron_hoe.png",
  ),
  "iron_horse_armor": MinecraftMaterial(
    name: "Iron Horse Armor",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/iron_horse_armor.png",
  ),
  "iron_ingot": MinecraftMaterial(
    name: "Iron Ingot",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/iron_ingot.png",
  ),
  "iron_leggings": MinecraftMaterial(
    name: "Iron Leggings",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/iron_leggings.png",
  ),
  "iron_nugget": MinecraftMaterial(
    name: "Iron Nugget",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/iron_nugget.png",
  ),
  "iron_ore": MinecraftMaterial(
    name: "Iron Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/iron_ore.png",
  ),
  "iron_pickaxe": MinecraftMaterial(
    name: "Iron Pickaxe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/iron_pickaxe.png",
  ),
  "iron_shovel": MinecraftMaterial(
    name: "Iron Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/iron_shovel.png",
  ),
  "iron_sword": MinecraftMaterial(
    name: "Iron Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/iron_sword.png",
  ),
  "iron_trapdoor": MinecraftMaterial(
    name: "Iron Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/iron_trapdoor.png",
  ),
  "item_frame": MinecraftMaterial(
    name: "Item Frame",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/item_frame.png",
  ),
  "jack_o_lantern": MinecraftMaterial(
    name: "Jack O Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/jack_o_lantern.png",
  ),
  "jigsaw": MinecraftMaterial(
    name: "Jigsaw",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/jigsaw.png",
  ),
  "jukebox": MinecraftMaterial(
    name: "Jukebox",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jukebox.png",
  ),
  "jungle_boat": MinecraftMaterial(
    name: "Jungle Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/jungle_boat.png",
  ),
  "jungle_button": MinecraftMaterial(
    name: "Jungle Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/jungle_button.png",
  ),
  "jungle_chest_boat": MinecraftMaterial(
    name: "Jungle Chest Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/jungle_chest_boat.png",
  ),
  "jungle_door": MinecraftMaterial(
    name: "Jungle Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_door.png",
  ),
  "jungle_fence": MinecraftMaterial(
    name: "Jungle Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_fence.png",
  ),
  "jungle_fence_gate": MinecraftMaterial(
    name: "Jungle Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_fence_gate.png",
  ),
  "jungle_hanging_sign": MinecraftMaterial(
    name: "Jungle Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/jungle_hanging_sign.png",
  ),
  "jungle_leaves": MinecraftMaterial(
    name: "Jungle Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_leaves.png",
  ),
  "jungle_log": MinecraftMaterial(
    name: "Jungle Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_log.png",
  ),
  "jungle_planks": MinecraftMaterial(
    name: "Jungle Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_planks.png",
  ),
  "jungle_pressure_plate": MinecraftMaterial(
    name: "Jungle Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_pressure_plate.png",
  ),
  "jungle_sapling": MinecraftMaterial(
    name: "Jungle Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/jungle_sapling.png",
  ),
  "jungle_sign": MinecraftMaterial(
    name: "Jungle Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_sign.png",
  ),
  "jungle_slab": MinecraftMaterial(
    name: "Jungle Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_slab.png",
  ),
  "jungle_stairs": MinecraftMaterial(
    name: "Jungle Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_stairs.png",
  ),
  "jungle_trapdoor": MinecraftMaterial(
    name: "Jungle Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_trapdoor.png",
  ),
  "jungle_wood": MinecraftMaterial(
    name: "Jungle Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_wood.png",
  ),
  "kelp": MinecraftMaterial(
    name: "Kelp",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/kelp.png",
  ),
  "knowledge_book": MinecraftMaterial(
    name: "Knowledge Book",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/knowledge_book.png",
  ),
  "ladder": MinecraftMaterial(
    name: "Ladder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/ladder.png",
  ),
  "lantern": MinecraftMaterial(
    name: "Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lantern.png",
  ),
  "lapis_block": MinecraftMaterial(
    name: "Lapis Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lapis_block.png",
  ),
  "lapis_lazuli": MinecraftMaterial(
    name: "Lapis Lazuli",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lapis_lazuli.png",
  ),
  "lapis_ore": MinecraftMaterial(
    name: "Lapis Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/lapis_ore.png",
  ),
  "large_amethyst_bud": MinecraftMaterial(
    name: "Large Amethyst Bud",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/large_amethyst_bud.png",
  ),
  "large_fern": MinecraftMaterial(
    name: "Large Fern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/large_fern.png",
  ),
  "lava": MinecraftMaterial(
    name: "Lava",
    properties: [
      MaterialProperty.block,
    ],
    icon: "assets/materials/lava.webp",
  ),
  "lava_bucket": MinecraftMaterial(
    name: "Lava Bucket",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/lava_bucket.png",
  ),
  "lead": MinecraftMaterial(
    name: "Lead",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lead.png",
  ),
  "leaf_litter": MinecraftMaterial(
    name: "Leaf Litter",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/leaf_litter.png",
  ),
  "leather": MinecraftMaterial(
    name: "Leather",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/leather.png",
  ),
  "leather_boots": MinecraftMaterial(
    name: "Leather Boots",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/leather_boots.png",
  ),
  "leather_chestplate": MinecraftMaterial(
    name: "Leather Chestplate",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/leather_chestplate.png",
  ),
  "leather_helmet": MinecraftMaterial(
    name: "Leather Helmet",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/leather_helmet.png",
  ),
  "leather_horse_armor": MinecraftMaterial(
    name: "Leather Horse Armor",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/leather_horse_armor.png",
  ),
  "leather_leggings": MinecraftMaterial(
    name: "Leather Leggings",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/leather_leggings.png",
  ),
  "lectern": MinecraftMaterial(
    name: "Lectern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/lectern.png",
  ),
  "lever": MinecraftMaterial(
    name: "Lever",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/lever.png",
  ),
  "light": MinecraftMaterial(
    name: "Light",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/light.png",
  ),
  "light_blue_banner": MinecraftMaterial(
    name: "Light Blue Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_blue_banner.png",
  ),
  "light_blue_bed": MinecraftMaterial(
    name: "Light Blue Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_blue_bed.png",
  ),
  "light_blue_bundle": MinecraftMaterial(
    name: "Light Blue Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_blue_bundle.png",
  ),
  "light_blue_candle": MinecraftMaterial(
    name: "Light Blue Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/light_blue_candle.png",
  ),
  "light_blue_carpet": MinecraftMaterial(
    name: "Light Blue Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_blue_carpet.png",
  ),
  "light_blue_concrete": MinecraftMaterial(
    name: "Light Blue Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_concrete.png",
  ),
  "light_blue_concrete_powder": MinecraftMaterial(
    name: "Light Blue Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_concrete_powder.png",
  ),
  "light_blue_dye": MinecraftMaterial(
    name: "Light Blue Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_blue_dye.png",
  ),
  "light_blue_glazed_terracotta": MinecraftMaterial(
    name: "Light Blue Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_glazed_terracotta.png",
  ),
  "light_blue_harness": MinecraftMaterial(
    name: "Light Blue Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_blue_harness.png",
  ),
  "light_blue_shulker_box": MinecraftMaterial(
    name: "Light Blue Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_shulker_box.png",
  ),
  "light_blue_stained_glass": MinecraftMaterial(
    name: "Light Blue Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_stained_glass.png",
  ),
  "light_blue_stained_glass_pane": MinecraftMaterial(
    name: "Light Blue Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_stained_glass_pane.png",
  ),
  "light_blue_terracotta": MinecraftMaterial(
    name: "Light Blue Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_terracotta.png",
  ),
  "light_blue_wool": MinecraftMaterial(
    name: "Light Blue Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_blue_wool.png",
  ),
  "light_gray_banner": MinecraftMaterial(
    name: "Light Gray Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_gray_banner.png",
  ),
  "light_gray_bed": MinecraftMaterial(
    name: "Light Gray Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_gray_bed.png",
  ),
  "light_gray_bundle": MinecraftMaterial(
    name: "Light Gray Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_gray_bundle.png",
  ),
  "light_gray_candle": MinecraftMaterial(
    name: "Light Gray Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/light_gray_candle.png",
  ),
  "light_gray_carpet": MinecraftMaterial(
    name: "Light Gray Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_gray_carpet.png",
  ),
  "light_gray_concrete": MinecraftMaterial(
    name: "Light Gray Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_concrete.png",
  ),
  "light_gray_concrete_powder": MinecraftMaterial(
    name: "Light Gray Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_concrete_powder.png",
  ),
  "light_gray_dye": MinecraftMaterial(
    name: "Light Gray Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_gray_dye.png",
  ),
  "light_gray_glazed_terracotta": MinecraftMaterial(
    name: "Light Gray Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_glazed_terracotta.png",
  ),
  "light_gray_harness": MinecraftMaterial(
    name: "Light Gray Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_gray_harness.png",
  ),
  "light_gray_shulker_box": MinecraftMaterial(
    name: "Light Gray Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_shulker_box.png",
  ),
  "light_gray_stained_glass": MinecraftMaterial(
    name: "Light Gray Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_stained_glass.png",
  ),
  "light_gray_stained_glass_pane": MinecraftMaterial(
    name: "Light Gray Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_stained_glass_pane.png",
  ),
  "light_gray_terracotta": MinecraftMaterial(
    name: "Light Gray Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_terracotta.png",
  ),
  "light_gray_wool": MinecraftMaterial(
    name: "Light Gray Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_gray_wool.png",
  ),
  "light_weighted_pressure_plate": MinecraftMaterial(
    name: "Light Weighted Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_weighted_pressure_plate.png",
  ),
  "lightning_rod": MinecraftMaterial(
    name: "Lightning Rod",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lightning_rod.png",
  ),
  "lilac": MinecraftMaterial(
    name: "Lilac",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/lilac.png",
  ),
  "lily_of_the_valley": MinecraftMaterial(
    name: "Lily Of The Valley",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/lily_of_the_valley.png",
  ),
  "lily_pad": MinecraftMaterial(
    name: "Lily Pad",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/lily_pad.png",
  ),
  "lime_banner": MinecraftMaterial(
    name: "Lime Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/lime_banner.png",
  ),
  "lime_bed": MinecraftMaterial(
    name: "Lime Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/lime_bed.png",
  ),
  "lime_bundle": MinecraftMaterial(
    name: "Lime Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lime_bundle.png",
  ),
  "lime_candle": MinecraftMaterial(
    name: "Lime Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/lime_candle.png",
  ),
  "lime_carpet": MinecraftMaterial(
    name: "Lime Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/lime_carpet.png",
  ),
  "lime_concrete": MinecraftMaterial(
    name: "Lime Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_concrete.png",
  ),
  "lime_concrete_powder": MinecraftMaterial(
    name: "Lime Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_concrete_powder.png",
  ),
  "lime_dye": MinecraftMaterial(
    name: "Lime Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lime_dye.png",
  ),
  "lime_glazed_terracotta": MinecraftMaterial(
    name: "Lime Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_glazed_terracotta.png",
  ),
  "lime_harness": MinecraftMaterial(
    name: "Lime Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lime_harness.png",
  ),
  "lime_shulker_box": MinecraftMaterial(
    name: "Lime Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_shulker_box.png",
  ),
  "lime_stained_glass": MinecraftMaterial(
    name: "Lime Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_stained_glass.png",
  ),
  "lime_stained_glass_pane": MinecraftMaterial(
    name: "Lime Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_stained_glass_pane.png",
  ),
  "lime_terracotta": MinecraftMaterial(
    name: "Lime Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_terracotta.png",
  ),
  "lime_wool": MinecraftMaterial(
    name: "Lime Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/lime_wool.png",
  ),
  "lingering_potion": MinecraftMaterial(
    name: "Lingering Potion",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lingering_potion.png",
  ),
  "llama_spawn_egg": MinecraftMaterial(
    name: "Llama Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/llama_spawn_egg.png",
  ),
  "lodestone": MinecraftMaterial(
    name: "Lodestone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lodestone.png",
  ),
  "loom": MinecraftMaterial(
    name: "Loom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/loom.png",
  ),
  "mace": MinecraftMaterial(
    name: "Mace",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/mace.png",
  ),
  "magenta_banner": MinecraftMaterial(
    name: "Magenta Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/magenta_banner.png",
  ),
  "magenta_bed": MinecraftMaterial(
    name: "Magenta Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/magenta_bed.png",
  ),
  "magenta_bundle": MinecraftMaterial(
    name: "Magenta Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/magenta_bundle.png",
  ),
  "magenta_candle": MinecraftMaterial(
    name: "Magenta Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/magenta_candle.png",
  ),
  "magenta_carpet": MinecraftMaterial(
    name: "Magenta Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/magenta_carpet.png",
  ),
  "magenta_concrete": MinecraftMaterial(
    name: "Magenta Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_concrete.png",
  ),
  "magenta_concrete_powder": MinecraftMaterial(
    name: "Magenta Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_concrete_powder.png",
  ),
  "magenta_dye": MinecraftMaterial(
    name: "Magenta Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/magenta_dye.png",
  ),
  "magenta_glazed_terracotta": MinecraftMaterial(
    name: "Magenta Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_glazed_terracotta.png",
  ),
  "magenta_harness": MinecraftMaterial(
    name: "Magenta Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/magenta_harness.png",
  ),
  "magenta_shulker_box": MinecraftMaterial(
    name: "Magenta Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_shulker_box.png",
  ),
  "magenta_stained_glass": MinecraftMaterial(
    name: "Magenta Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_stained_glass.png",
  ),
  "magenta_stained_glass_pane": MinecraftMaterial(
    name: "Magenta Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_stained_glass_pane.png",
  ),
  "magenta_terracotta": MinecraftMaterial(
    name: "Magenta Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_terracotta.png",
  ),
  "magenta_wool": MinecraftMaterial(
    name: "Magenta Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/magenta_wool.png",
  ),
  "magma_block": MinecraftMaterial(
    name: "Magma Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magma_block.png",
  ),
  "magma_cream": MinecraftMaterial(
    name: "Magma Cream",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/magma_cream.png",
  ),
  "magma_cube_spawn_egg": MinecraftMaterial(
    name: "Magma Cube Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/magma_cube_spawn_egg.png",
  ),
  "mangrove_boat": MinecraftMaterial(
    name: "Mangrove Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/mangrove_boat.png",
  ),
  "mangrove_button": MinecraftMaterial(
    name: "Mangrove Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/mangrove_button.png",
  ),
  "mangrove_chest_boat": MinecraftMaterial(
    name: "Mangrove Chest Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/mangrove_chest_boat.png",
  ),
  "mangrove_door": MinecraftMaterial(
    name: "Mangrove Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_door.png",
  ),
  "mangrove_fence": MinecraftMaterial(
    name: "Mangrove Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_fence.png",
  ),
  "mangrove_fence_gate": MinecraftMaterial(
    name: "Mangrove Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_fence_gate.png",
  ),
  "mangrove_hanging_sign": MinecraftMaterial(
    name: "Mangrove Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/mangrove_hanging_sign.png",
  ),
  "mangrove_leaves": MinecraftMaterial(
    name: "Mangrove Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_leaves.png",
  ),
  "mangrove_log": MinecraftMaterial(
    name: "Mangrove Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_log.png",
  ),
  "mangrove_planks": MinecraftMaterial(
    name: "Mangrove Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_planks.png",
  ),
  "mangrove_pressure_plate": MinecraftMaterial(
    name: "Mangrove Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_pressure_plate.png",
  ),
  "mangrove_propagule": MinecraftMaterial(
    name: "Mangrove Propagule",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/mangrove_propagule.png",
  ),
  "mangrove_roots": MinecraftMaterial(
    name: "Mangrove Roots",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_roots.png",
  ),
  "mangrove_sign": MinecraftMaterial(
    name: "Mangrove Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_sign.png",
  ),
  "mangrove_slab": MinecraftMaterial(
    name: "Mangrove Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_slab.png",
  ),
  "mangrove_stairs": MinecraftMaterial(
    name: "Mangrove Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_stairs.png",
  ),
  "mangrove_trapdoor": MinecraftMaterial(
    name: "Mangrove Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_trapdoor.png",
  ),
  "mangrove_wood": MinecraftMaterial(
    name: "Mangrove Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_wood.png",
  ),
  "map": MinecraftMaterial(
    name: "Map",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/map.png",
  ),
  "medium_amethyst_bud": MinecraftMaterial(
    name: "Medium Amethyst Bud",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/medium_amethyst_bud.png",
  ),
  "melon": MinecraftMaterial(
    name: "Melon",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/melon.png",
  ),
  "melon_seeds": MinecraftMaterial(
    name: "Melon Seeds",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/melon_seeds.png",
  ),
  "melon_slice": MinecraftMaterial(
    name: "Melon Slice",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/melon_slice.png",
  ),
  "milk_bucket": MinecraftMaterial(
    name: "Milk Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/milk_bucket.png",
  ),
  "minecart": MinecraftMaterial(
    name: "Minecart",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/minecart.png",
  ),
  "miner_pottery_sherd": MinecraftMaterial(
    name: "Miner Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/miner_pottery_sherd.png",
  ),
  "mojang_banner_pattern": MinecraftMaterial(
    name: "Mojang Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/mojang_banner_pattern.png",
  ),
  "mooshroom_spawn_egg": MinecraftMaterial(
    name: "Mooshroom Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/mooshroom_spawn_egg.png",
  ),
  "moss_block": MinecraftMaterial(
    name: "Moss Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/moss_block.png",
  ),
  "moss_carpet": MinecraftMaterial(
    name: "Moss Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/moss_carpet.png",
  ),
  "mossy_cobblestone": MinecraftMaterial(
    name: "Mossy Cobblestone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_cobblestone.png",
  ),
  "mossy_cobblestone_slab": MinecraftMaterial(
    name: "Mossy Cobblestone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_cobblestone_slab.png",
  ),
  "mossy_cobblestone_stairs": MinecraftMaterial(
    name: "Mossy Cobblestone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_cobblestone_stairs.png",
  ),
  "mossy_cobblestone_wall": MinecraftMaterial(
    name: "Mossy Cobblestone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_cobblestone_wall.png",
  ),
  "mossy_stone_brick_slab": MinecraftMaterial(
    name: "Mossy Stone Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_stone_brick_slab.png",
  ),
  "mossy_stone_brick_stairs": MinecraftMaterial(
    name: "Mossy Stone Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_stone_brick_stairs.png",
  ),
  "mossy_stone_brick_wall": MinecraftMaterial(
    name: "Mossy Stone Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_stone_brick_wall.png",
  ),
  "mossy_stone_bricks": MinecraftMaterial(
    name: "Mossy Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_stone_bricks.png",
  ),
  "mourner_pottery_sherd": MinecraftMaterial(
    name: "Mourner Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/mourner_pottery_sherd.png",
  ),
  "mud": MinecraftMaterial(
    name: "Mud",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mud.png",
  ),
  "mud_brick_slab": MinecraftMaterial(
    name: "Mud Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mud_brick_slab.png",
  ),
  "mud_brick_stairs": MinecraftMaterial(
    name: "Mud Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mud_brick_stairs.png",
  ),
  "mud_brick_wall": MinecraftMaterial(
    name: "Mud Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mud_brick_wall.png",
  ),
  "mud_bricks": MinecraftMaterial(
    name: "Mud Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mud_bricks.png",
  ),
  "muddy_mangrove_roots": MinecraftMaterial(
    name: "Muddy Mangrove Roots",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/muddy_mangrove_roots.png",
  ),
  "mule_spawn_egg": MinecraftMaterial(
    name: "Mule Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/mule_spawn_egg.png",
  ),
  "mushroom_stem": MinecraftMaterial(
    name: "Mushroom Stem",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mushroom_stem.png",
  ),
  "mushroom_stew": MinecraftMaterial(
    name: "Mushroom Stew",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/mushroom_stew.png",
  ),
  "music_disc_11": MinecraftMaterial(
    name: "Music Disc 11",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_11.png",
  ),
  "music_disc_13": MinecraftMaterial(
    name: "Music Disc 13",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_13.png",
  ),
  "music_disc_5": MinecraftMaterial(
    name: "Music Disc 5",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_5.png",
  ),
  "music_disc_blocks": MinecraftMaterial(
    name: "Music Disc Blocks",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_blocks.png",
  ),
  "music_disc_cat": MinecraftMaterial(
    name: "Music Disc Cat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_cat.png",
  ),
  "music_disc_chirp": MinecraftMaterial(
    name: "Music Disc Chirp",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_chirp.png",
  ),
  "music_disc_creator": MinecraftMaterial(
    name: "Music Disc",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_creator.png",
  ),
  "music_disc_creator_music_box": MinecraftMaterial(
    name: "Music Disc",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_creator_music_box.png",
  ),
  "music_disc_far": MinecraftMaterial(
    name: "Music Disc Far",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_far.png",
  ),
  "music_disc_lava_chicken": MinecraftMaterial(
    name: "Music Disc",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_lava_chicken.png",
  ),
  "music_disc_mall": MinecraftMaterial(
    name: "Music Disc Mall",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_mall.png",
  ),
  "music_disc_mellohi": MinecraftMaterial(
    name: "Music Disc Mellohi",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_mellohi.png",
  ),
  "music_disc_otherside": MinecraftMaterial(
    name: "Music Disc Otherside",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_otherside.png",
  ),
  "music_disc_pigstep": MinecraftMaterial(
    name: "Music Disc Pigstep",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_pigstep.png",
  ),
  "music_disc_precipice": MinecraftMaterial(
    name: "Music Disc",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_precipice.png",
  ),
  "music_disc_relic": MinecraftMaterial(
    name: "Music Disc",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_relic.png",
  ),
  "music_disc_stal": MinecraftMaterial(
    name: "Music Disc Stal",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_stal.png",
  ),
  "music_disc_strad": MinecraftMaterial(
    name: "Music Disc Strad",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_strad.png",
  ),
  "music_disc_tears": MinecraftMaterial(
    name: "Music Disc",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_tears.png",
  ),
  "music_disc_wait": MinecraftMaterial(
    name: "Music Disc Wait",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_wait.png",
  ),
  "music_disc_ward": MinecraftMaterial(
    name: "Music Disc Ward",
    properties: [
      MaterialProperty.item,
      MaterialProperty.record,
    ],
    icon: "assets/materials/music_disc_ward.png",
  ),
  "mutton": MinecraftMaterial(
    name: "Mutton",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/mutton.png",
  ),
  "mycelium": MinecraftMaterial(
    name: "Mycelium",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mycelium.png",
  ),
  "name_tag": MinecraftMaterial(
    name: "Name Tag",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/name_tag.png",
  ),
  "nautilus_shell": MinecraftMaterial(
    name: "Nautilus Shell",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/nautilus_shell.png",
  ),
  "nether_brick": MinecraftMaterial(
    name: "Nether Brick",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/nether_brick.png",
  ),
  "nether_brick_fence": MinecraftMaterial(
    name: "Nether Brick Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/nether_brick_fence.png",
  ),
  "nether_brick_slab": MinecraftMaterial(
    name: "Nether Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/nether_brick_slab.png",
  ),
  "nether_brick_stairs": MinecraftMaterial(
    name: "Nether Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/nether_brick_stairs.png",
  ),
  "nether_brick_wall": MinecraftMaterial(
    name: "Nether Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/nether_brick_wall.png",
  ),
  "nether_bricks": MinecraftMaterial(
    name: "Nether Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/nether_bricks.png",
  ),
  "nether_gold_ore": MinecraftMaterial(
    name: "Nether Gold Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/nether_gold_ore.png",
  ),
  "nether_quartz_ore": MinecraftMaterial(
    name: "Nether Quartz Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/nether_quartz_ore.png",
  ),
  "nether_sprouts": MinecraftMaterial(
    name: "Nether Sprouts",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/nether_sprouts.png",
  ),
  "nether_star": MinecraftMaterial(
    name: "Nether Star",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/nether_star.png",
  ),
  "nether_wart": MinecraftMaterial(
    name: "Nether Wart",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/nether_wart.png",
  ),
  "nether_wart_block": MinecraftMaterial(
    name: "Nether Wart Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/nether_wart_block.png",
  ),
  "netherite_axe": MinecraftMaterial(
    name: "Netherite Axe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/netherite_axe.png",
  ),
  "netherite_block": MinecraftMaterial(
    name: "Netherite Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/netherite_block.png",
  ),
  "netherite_boots": MinecraftMaterial(
    name: "Netherite Boots",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/netherite_boots.png",
  ),
  "netherite_chestplate": MinecraftMaterial(
    name: "Netherite Chestplate",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/netherite_chestplate.png",
  ),
  "netherite_helmet": MinecraftMaterial(
    name: "Netherite Helmet",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/netherite_helmet.png",
  ),
  "netherite_hoe": MinecraftMaterial(
    name: "Netherite Hoe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/netherite_hoe.png",
  ),
  "netherite_ingot": MinecraftMaterial(
    name: "Netherite Ingot",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/netherite_ingot.png",
  ),
  "netherite_leggings": MinecraftMaterial(
    name: "Netherite Leggings",
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/netherite_leggings.png",
  ),
  "netherite_pickaxe": MinecraftMaterial(
    name: "Netherite Pickaxe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/netherite_pickaxe.png",
  ),
  "netherite_scrap": MinecraftMaterial(
    name: "Netherite Scrap",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/netherite_scrap.png",
  ),
  "netherite_shovel": MinecraftMaterial(
    name: "Netherite Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/netherite_shovel.png",
  ),
  "netherite_sword": MinecraftMaterial(
    name: "Netherite Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/netherite_sword.png",
  ),
  "netherite_upgrade_smithing_template": MinecraftMaterial(
    name: "Netherite Upgrade",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/netherite_upgrade_smithing_template.png",
  ),
  "netherrack": MinecraftMaterial(
    name: "Netherrack",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/netherrack.png",
  ),
  "note_block": MinecraftMaterial(
    name: "Note Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/note_block.png",
  ),
  "oak_boat": MinecraftMaterial(
    name: "Oak Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/oak_boat.png",
  ),
  "oak_button": MinecraftMaterial(
    name: "Oak Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/oak_button.png",
  ),
  "oak_chest_boat": MinecraftMaterial(
    name: "Oak Chest Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/oak_chest_boat.png",
  ),
  "oak_door": MinecraftMaterial(
    name: "Oak Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_door.png",
  ),
  "oak_fence": MinecraftMaterial(
    name: "Oak Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_fence.png",
  ),
  "oak_fence_gate": MinecraftMaterial(
    name: "Oak Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_fence_gate.png",
  ),
  "oak_hanging_sign": MinecraftMaterial(
    name: "Oak Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oak_hanging_sign.png",
  ),
  "oak_leaves": MinecraftMaterial(
    name: "Oak Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_leaves.png",
  ),
  "oak_log": MinecraftMaterial(
    name: "Oak Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_log.png",
  ),
  "oak_planks": MinecraftMaterial(
    name: "Oak Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_planks.png",
  ),
  "oak_pressure_plate": MinecraftMaterial(
    name: "Oak Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_pressure_plate.png",
  ),
  "oak_sapling": MinecraftMaterial(
    name: "Oak Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/oak_sapling.png",
  ),
  "oak_sign": MinecraftMaterial(
    name: "Oak Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_sign.png",
  ),
  "oak_slab": MinecraftMaterial(
    name: "Oak Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_slab.png",
  ),
  "oak_stairs": MinecraftMaterial(
    name: "Oak Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_stairs.png",
  ),
  "oak_trapdoor": MinecraftMaterial(
    name: "Oak Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_trapdoor.png",
  ),
  "oak_wood": MinecraftMaterial(
    name: "Oak Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_wood.png",
  ),
  "observer": MinecraftMaterial(
    name: "Observer",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/observer.png",
  ),
  "obsidian": MinecraftMaterial(
    name: "Obsidian",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/obsidian.png",
  ),
  "ocelot_spawn_egg": MinecraftMaterial(
    name: "Ocelot Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ocelot_spawn_egg.png",
  ),
  "ochre_froglight": MinecraftMaterial(
    name: "Ochre Froglight",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/ochre_froglight.png",
  ),
  "ominous_bottle": MinecraftMaterial(
    name: "Ominous Bottle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ominous_bottle.png",
  ),
  "ominous_trial_key": MinecraftMaterial(
    name: "Ominous Trial Key",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ominous_trial_key.png",
  ),
  "open_eyeblossom": MinecraftMaterial(
    name: "Open Eyeblossom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/open_eyeblossom.png",
  ),
  "orange_banner": MinecraftMaterial(
    name: "Orange Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/orange_banner.png",
  ),
  "orange_bed": MinecraftMaterial(
    name: "Orange Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/orange_bed.png",
  ),
  "orange_bundle": MinecraftMaterial(
    name: "Orange Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/orange_bundle.png",
  ),
  "orange_candle": MinecraftMaterial(
    name: "Orange Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/orange_candle.png",
  ),
  "orange_carpet": MinecraftMaterial(
    name: "Orange Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/orange_carpet.png",
  ),
  "orange_concrete": MinecraftMaterial(
    name: "Orange Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_concrete.png",
  ),
  "orange_concrete_powder": MinecraftMaterial(
    name: "Orange Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_concrete_powder.png",
  ),
  "orange_dye": MinecraftMaterial(
    name: "Orange Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/orange_dye.png",
  ),
  "orange_glazed_terracotta": MinecraftMaterial(
    name: "Orange Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_glazed_terracotta.png",
  ),
  "orange_harness": MinecraftMaterial(
    name: "Orange Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/orange_harness.png",
  ),
  "orange_shulker_box": MinecraftMaterial(
    name: "Orange Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_shulker_box.png",
  ),
  "orange_stained_glass": MinecraftMaterial(
    name: "Orange Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_stained_glass.png",
  ),
  "orange_stained_glass_pane": MinecraftMaterial(
    name: "Orange Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_stained_glass_pane.png",
  ),
  "orange_terracotta": MinecraftMaterial(
    name: "Orange Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_terracotta.png",
  ),
  "orange_tulip": MinecraftMaterial(
    name: "Orange Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/orange_tulip.png",
  ),
  "orange_wool": MinecraftMaterial(
    name: "Orange Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/orange_wool.png",
  ),
  "oxeye_daisy": MinecraftMaterial(
    name: "Oxeye Daisy",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/oxeye_daisy.png",
  ),
  "oxidized_chiseled_copper": MinecraftMaterial(
    name: "Oxidized Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_chiseled_copper.png",
  ),
  "oxidized_copper": MinecraftMaterial(
    name: "Oxidized Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/oxidized_copper.png",
  ),
  "oxidized_copper_bulb": MinecraftMaterial(
    name: "Oxidized Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_bulb.png",
  ),
  "oxidized_copper_door": MinecraftMaterial(
    name: "Oxidized Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_door.png",
  ),
  "oxidized_copper_grate": MinecraftMaterial(
    name: "Oxidized Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_grate.png",
  ),
  "oxidized_copper_trapdoor": MinecraftMaterial(
    name: "Oxidized Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_trapdoor.png",
  ),
  "oxidized_copper_chain": MinecraftMaterial(
    name: "Oxidized Copper Chain",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_chain.png",
  ),
  "oxidized_copper_lantern": MinecraftMaterial(
    name: "Oxidized Copper Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_lantern.png",
  ),
  "oxidized_cut_copper": MinecraftMaterial(
    name: "Oxidized Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/oxidized_cut_copper.png",
  ),
  "oxidized_cut_copper_slab": MinecraftMaterial(
    name: "Oxidized Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/oxidized_cut_copper_slab.png",
  ),
  "oxidized_cut_copper_stairs": MinecraftMaterial(
    name: "Oxidized Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/oxidized_cut_copper_stairs.png",
  ),
  "packed_ice": MinecraftMaterial(
    name: "Packed Ice",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/packed_ice.png",
  ),
  "packed_mud": MinecraftMaterial(
    name: "Packed Mud",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/packed_mud.png",
  ),
  "painting": MinecraftMaterial(
    name: "Painting",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/painting.png",
  ),
  "pale_hanging_moss": MinecraftMaterial(
    name: "Pale Hanging Moss",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_hanging_moss.png",
  ),
  "pale_moss_block": MinecraftMaterial(
    name: "Pale Moss Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_moss_block.png",
  ),
  "pale_moss_carpet": MinecraftMaterial(
    name: "Pale Moss Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_moss_carpet.png",
  ),
  "pale_oak_boat": MinecraftMaterial(
    name: "Pale Oak Boat",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_boat.png",
  ),
  "pale_oak_button": MinecraftMaterial(
    name: "Pale Oak Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_button.png",
  ),
  "pale_oak_chest_boat": MinecraftMaterial(
    name: "Pale Oak Boat with Chest",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_chest_boat.png",
  ),
  "pale_oak_door": MinecraftMaterial(
    name: "Pale Oak Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_door.png",
  ),
  "pale_oak_fence": MinecraftMaterial(
    name: "Pale Oak Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_fence.png",
  ),
  "pale_oak_fence_gate": MinecraftMaterial(
    name: "Pale Oak Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_fence_gate.png",
  ),
  "pale_oak_hanging_sign": MinecraftMaterial(
    name: "Pale Oak Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_hanging_sign.png",
  ),
  "pale_oak_leaves": MinecraftMaterial(
    name: "Pale Oak Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_leaves.png",
  ),
  "pale_oak_log": MinecraftMaterial(
    name: "Pale Oak Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_log.png",
  ),
  "pale_oak_planks": MinecraftMaterial(
    name: "Pale Oak Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_planks.png",
  ),
  "pale_oak_pressure_plate": MinecraftMaterial(
    name: "Pale Oak Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_pressure_plate.png",
  ),
  "pale_oak_sapling": MinecraftMaterial(
    name: "Pale Oak Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_sapling.png",
  ),
  "pale_oak_sign": MinecraftMaterial(
    name: "Pale Oak Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_sign.png",
  ),
  "pale_oak_slab": MinecraftMaterial(
    name: "Pale Oak Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_slab.png",
  ),
  "pale_oak_stairs": MinecraftMaterial(
    name: "Pale Oak Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_stairs.png",
  ),
  "pale_oak_trapdoor": MinecraftMaterial(
    name: "Pale Oak Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_trapdoor.png",
  ),
  "pale_oak_wood": MinecraftMaterial(
    name: "Pale Oak Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_wood.png",
  ),
  "panda_spawn_egg": MinecraftMaterial(
    name: "Panda Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/panda_spawn_egg.png",
  ),
  "paper": MinecraftMaterial(
    name: "Paper",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/paper.png",
  ),
  "parrot_spawn_egg": MinecraftMaterial(
    name: "Parrot Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/parrot_spawn_egg.png",
  ),
  "pearlescent_froglight": MinecraftMaterial(
    name: "Pearlescent Froglight",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pearlescent_froglight.png",
  ),
  "peony": MinecraftMaterial(
    name: "Peony",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/peony.png",
  ),
  "petrified_oak_slab": MinecraftMaterial(
    name: "Petrified Oak Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/petrified_oak_slab.png",
  ),
  "phantom_membrane": MinecraftMaterial(
    name: "Phantom Membrane",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/phantom_membrane.png",
  ),
  "phantom_spawn_egg": MinecraftMaterial(
    name: "Phantom Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/phantom_spawn_egg.png",
  ),
  "pig_spawn_egg": MinecraftMaterial(
    name: "Pig Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pig_spawn_egg.png",
  ),
  "piglin_banner_pattern": MinecraftMaterial(
    name: "Piglin Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/piglin_banner_pattern.png",
  ),
  "piglin_brute_spawn_egg": MinecraftMaterial(
    name: "Piglin Brute Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/piglin_brute_spawn_egg.png",
  ),
  "piglin_head": MinecraftMaterial(
    name: "Piglin Head",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/piglin_head.png",
  ),
  "piglin_spawn_egg": MinecraftMaterial(
    name: "Piglin Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/piglin_spawn_egg.png",
  ),
  "pillager_spawn_egg": MinecraftMaterial(
    name: "Pillager Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pillager_spawn_egg.png",
  ),
  "pink_banner": MinecraftMaterial(
    name: "Pink Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/pink_banner.png",
  ),
  "pink_bed": MinecraftMaterial(
    name: "Pink Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/pink_bed.png",
  ),
  "pink_bundle": MinecraftMaterial(
    name: "Pink Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pink_bundle.png",
  ),
  "pink_candle": MinecraftMaterial(
    name: "Pink Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/pink_candle.png",
  ),
  "pink_carpet": MinecraftMaterial(
    name: "Pink Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/pink_carpet.png",
  ),
  "pink_concrete": MinecraftMaterial(
    name: "Pink Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_concrete.png",
  ),
  "pink_concrete_powder": MinecraftMaterial(
    name: "Pink Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_concrete_powder.png",
  ),
  "pink_dye": MinecraftMaterial(
    name: "Pink Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pink_dye.png",
  ),
  "pink_glazed_terracotta": MinecraftMaterial(
    name: "Pink Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_glazed_terracotta.png",
  ),
  "pink_harness": MinecraftMaterial(
    name: "Pink Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pink_harness.png",
  ),
  "pink_petals": MinecraftMaterial(
    name: "Pink Petals",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pink_petals.png",
  ),
  "pink_shulker_box": MinecraftMaterial(
    name: "Pink Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_shulker_box.png",
  ),
  "pink_stained_glass": MinecraftMaterial(
    name: "Pink Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_stained_glass.png",
  ),
  "pink_stained_glass_pane": MinecraftMaterial(
    name: "Pink Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_stained_glass_pane.png",
  ),
  "pink_terracotta": MinecraftMaterial(
    name: "Pink Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_terracotta.png",
  ),
  "pink_tulip": MinecraftMaterial(
    name: "Pink Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/pink_tulip.png",
  ),
  "pink_wool": MinecraftMaterial(
    name: "Pink Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/pink_wool.png",
  ),
  "piston": MinecraftMaterial(
    name: "Piston",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/piston.png",
  ),
  "pitcher_plant": MinecraftMaterial(
    name: "Pitcher Plant",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pitcher_plant.png",
  ),
  "pitcher_pod": MinecraftMaterial(
    name: "Pitcher Pod",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pitcher_pod.png",
  ),
  "player_head": MinecraftMaterial(
    name: "Player Head",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/player_head.png",
  ),
  "plenty_pottery_sherd": MinecraftMaterial(
    name: "Plenty Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/plenty_pottery_sherd.png",
  ),
  "podzol": MinecraftMaterial(
    name: "Podzol",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/podzol.png",
  ),
  "pointed_dripstone": MinecraftMaterial(
    name: "Pointed Dripstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pointed_dripstone.png",
  ),
  "poisonous_potato": MinecraftMaterial(
    name: "Poisonous Potato",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/poisonous_potato.png",
  ),
  "polar_bear_spawn_egg": MinecraftMaterial(
    name: "Polar Bear Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/polar_bear_spawn_egg.png",
  ),
  "polished_andesite": MinecraftMaterial(
    name: "Polished Andesite",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_andesite.png",
  ),
  "polished_andesite_slab": MinecraftMaterial(
    name: "Polished Andesite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_andesite_slab.png",
  ),
  "polished_andesite_stairs": MinecraftMaterial(
    name: "Polished Andesite Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_andesite_stairs.png",
  ),
  "polished_basalt": MinecraftMaterial(
    name: "Polished Basalt",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_basalt.png",
  ),
  "polished_blackstone": MinecraftMaterial(
    name: "Polished Blackstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone.png",
  ),
  "polished_blackstone_brick_slab": MinecraftMaterial(
    name: "Polished Blackstone Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_brick_slab.png",
  ),
  "polished_blackstone_brick_stairs": MinecraftMaterial(
    name: "Polished Blackstone Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_brick_stairs.png",
  ),
  "polished_blackstone_brick_wall": MinecraftMaterial(
    name: "Polished Blackstone Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_brick_wall.png",
  ),
  "polished_blackstone_bricks": MinecraftMaterial(
    name: "Polished Blackstone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_bricks.png",
  ),
  "polished_blackstone_button": MinecraftMaterial(
    name: "Polished Blackstone Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/polished_blackstone_button.png",
  ),
  "polished_blackstone_pressure_plate": MinecraftMaterial(
    name: "Polished Blackstone Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_pressure_plate.png",
  ),
  "polished_blackstone_slab": MinecraftMaterial(
    name: "Polished Blackstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_slab.png",
  ),
  "polished_blackstone_stairs": MinecraftMaterial(
    name: "Polished Blackstone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_stairs.png",
  ),
  "polished_blackstone_wall": MinecraftMaterial(
    name: "Polished Blackstone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_wall.png",
  ),
  "polished_deepslate": MinecraftMaterial(
    name: "Polished Deepslate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_deepslate.png",
  ),
  "polished_deepslate_slab": MinecraftMaterial(
    name: "Polished Deepslate Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_deepslate_slab.png",
  ),
  "polished_deepslate_stairs": MinecraftMaterial(
    name: "Polished Deepslate Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_deepslate_stairs.png",
  ),
  "polished_deepslate_wall": MinecraftMaterial(
    name: "Polished Deepslate Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_deepslate_wall.png",
  ),
  "polished_diorite": MinecraftMaterial(
    name: "Polished Diorite",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_diorite.png",
  ),
  "polished_diorite_slab": MinecraftMaterial(
    name: "Polished Diorite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_diorite_slab.png",
  ),
  "polished_diorite_stairs": MinecraftMaterial(
    name: "Polished Diorite Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_diorite_stairs.png",
  ),
  "polished_granite": MinecraftMaterial(
    name: "Polished Granite",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_granite.png",
  ),
  "polished_granite_slab": MinecraftMaterial(
    name: "Polished Granite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_granite_slab.png",
  ),
  "polished_granite_stairs": MinecraftMaterial(
    name: "Polished Granite Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_granite_stairs.png",
  ),
  "polished_tuff": MinecraftMaterial(
    name: "Polished Tuff",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/polished_tuff.png",
  ),
  "polished_tuff_slab": MinecraftMaterial(
    name: "Polished Tuff Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/polished_tuff_slab.png",
  ),
  "polished_tuff_stairs": MinecraftMaterial(
    name: "Polished Tuff Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/polished_tuff_stairs.png",
  ),
  "polished_tuff_wall": MinecraftMaterial(
    name: "Polished Tuff Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/polished_tuff_wall.png",
  ),
  "popped_chorus_fruit": MinecraftMaterial(
    name: "Popped Chorus Fruit",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/popped_chorus_fruit.png",
  ),
  "poppy": MinecraftMaterial(
    name: "Poppy",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/poppy.png",
  ),
  "porkchop": MinecraftMaterial(
    name: "Porkchop",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/porkchop.png",
  ),
  "potato": MinecraftMaterial(
    name: "Potato",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/potato.png",
  ),
  "potion": MinecraftMaterial(
    name: "Potion",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/potion.png",
  ),
  "powder_snow_bucket": MinecraftMaterial(
    name: "Powder Snow Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/powder_snow_bucket.png",
  ),
  "powered_rail": MinecraftMaterial(
    name: "Powered Rail",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/powered_rail.png",
  ),
  "prismarine": MinecraftMaterial(
    name: "Prismarine",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine.png",
  ),
  "prismarine_brick_slab": MinecraftMaterial(
    name: "Prismarine Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine_brick_slab.png",
  ),
  "prismarine_brick_stairs": MinecraftMaterial(
    name: "Prismarine Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine_brick_stairs.png",
  ),
  "prismarine_bricks": MinecraftMaterial(
    name: "Prismarine Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine_bricks.png",
  ),
  "prismarine_crystals": MinecraftMaterial(
    name: "Prismarine Crystals",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/prismarine_crystals.png",
  ),
  "prismarine_shard": MinecraftMaterial(
    name: "Prismarine Shard",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/prismarine_shard.png",
  ),
  "prismarine_slab": MinecraftMaterial(
    name: "Prismarine Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine_slab.png",
  ),
  "prismarine_stairs": MinecraftMaterial(
    name: "Prismarine Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine_stairs.png",
  ),
  "prismarine_wall": MinecraftMaterial(
    name: "Prismarine Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine_wall.png",
  ),
  "prize_pottery_sherd": MinecraftMaterial(
    name: "Prize Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/prize_pottery_sherd.png",
  ),
  "pufferfish": MinecraftMaterial(
    name: "Pufferfish",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/pufferfish.png",
  ),
  "pufferfish_bucket": MinecraftMaterial(
    name: "Pufferfish Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pufferfish_bucket.png",
  ),
  "pufferfish_spawn_egg": MinecraftMaterial(
    name: "Pufferfish Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pufferfish_spawn_egg.png",
  ),
  "pumpkin": MinecraftMaterial(
    name: "Pumpkin",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pumpkin.png",
  ),
  "pumpkin_pie": MinecraftMaterial(
    name: "Pumpkin Pie",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/pumpkin_pie.png",
  ),
  "pumpkin_seeds": MinecraftMaterial(
    name: "Pumpkin Seeds",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pumpkin_seeds.png",
  ),
  "purple_banner": MinecraftMaterial(
    name: "Purple Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/purple_banner.png",
  ),
  "purple_bed": MinecraftMaterial(
    name: "Purple Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/purple_bed.png",
  ),
  "purple_bundle": MinecraftMaterial(
    name: "Purple Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/purple_bundle.png",
  ),
  "purple_candle": MinecraftMaterial(
    name: "Purple Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/purple_candle.png",
  ),
  "purple_carpet": MinecraftMaterial(
    name: "Purple Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/purple_carpet.png",
  ),
  "purple_concrete": MinecraftMaterial(
    name: "Purple Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_concrete.png",
  ),
  "purple_concrete_powder": MinecraftMaterial(
    name: "Purple Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_concrete_powder.png",
  ),
  "purple_dye": MinecraftMaterial(
    name: "Purple Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/purple_dye.png",
  ),
  "purple_glazed_terracotta": MinecraftMaterial(
    name: "Purple Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_glazed_terracotta.png",
  ),
  "purple_harness": MinecraftMaterial(
    name: "Purple Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/purple_harness.png",
  ),
  "purple_shulker_box": MinecraftMaterial(
    name: "Purple Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_shulker_box.png",
  ),
  "purple_stained_glass": MinecraftMaterial(
    name: "Purple Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_stained_glass.png",
  ),
  "purple_stained_glass_pane": MinecraftMaterial(
    name: "Purple Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_stained_glass_pane.png",
  ),
  "purple_terracotta": MinecraftMaterial(
    name: "Purple Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_terracotta.png",
  ),
  "purple_wool": MinecraftMaterial(
    name: "Purple Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/purple_wool.png",
  ),
  "purpur_block": MinecraftMaterial(
    name: "Purpur Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purpur_block.png",
  ),
  "purpur_pillar": MinecraftMaterial(
    name: "Purpur Pillar",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purpur_pillar.png",
  ),
  "purpur_slab": MinecraftMaterial(
    name: "Purpur Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purpur_slab.png",
  ),
  "purpur_stairs": MinecraftMaterial(
    name: "Purpur Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purpur_stairs.png",
  ),
  "quartz": MinecraftMaterial(
    name: "Quartz",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/quartz.png",
  ),
  "quartz_block": MinecraftMaterial(
    name: "Quartz Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/quartz_block.png",
  ),
  "quartz_bricks": MinecraftMaterial(
    name: "Quartz Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/quartz_bricks.png",
  ),
  "quartz_pillar": MinecraftMaterial(
    name: "Quartz Pillar",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/quartz_pillar.png",
  ),
  "quartz_slab": MinecraftMaterial(
    name: "Quartz Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/quartz_slab.png",
  ),
  "quartz_stairs": MinecraftMaterial(
    name: "Quartz Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/quartz_stairs.png",
  ),
  "rabbit": MinecraftMaterial(
    name: "Rabbit",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/rabbit.png",
  ),
  "rabbit_foot": MinecraftMaterial(
    name: "Rabbit Foot",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/rabbit_foot.png",
  ),
  "rabbit_hide": MinecraftMaterial(
    name: "Rabbit Hide",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/rabbit_hide.png",
  ),
  "rabbit_spawn_egg": MinecraftMaterial(
    name: "Rabbit Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/rabbit_spawn_egg.png",
  ),
  "rabbit_stew": MinecraftMaterial(
    name: "Rabbit Stew",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/rabbit_stew.png",
  ),
  "rail": MinecraftMaterial(
    name: "Rail",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/rail.png",
  ),
  "raiser_armor_trim_smithing_template": MinecraftMaterial(
    name: "Raiser Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/raiser_armor_trim_smithing_template.png",
  ),
  "ravager_spawn_egg": MinecraftMaterial(
    name: "Ravager Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ravager_spawn_egg.png",
  ),
  "raw_copper": MinecraftMaterial(
    name: "Raw Copper",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/raw_copper.png",
  ),
  "raw_copper_block": MinecraftMaterial(
    name: "Raw Copper Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/raw_copper_block.png",
  ),
  "raw_gold": MinecraftMaterial(
    name: "Raw Gold",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/raw_gold.png",
  ),
  "raw_gold_block": MinecraftMaterial(
    name: "Raw Gold Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/raw_gold_block.png",
  ),
  "raw_iron": MinecraftMaterial(
    name: "Raw Iron",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/raw_iron.png",
  ),
  "raw_iron_block": MinecraftMaterial(
    name: "Raw Iron Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/raw_iron_block.png",
  ),
  "recovery_compass": MinecraftMaterial(
    name: "Recovery Compass",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/recovery_compass.png",
  ),
  "red_banner": MinecraftMaterial(
    name: "Red Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/red_banner.png",
  ),
  "red_bed": MinecraftMaterial(
    name: "Red Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/red_bed.png",
  ),
  "red_bundle": MinecraftMaterial(
    name: "Red Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/red_bundle.png",
  ),
  "red_candle": MinecraftMaterial(
    name: "Red Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/red_candle.png",
  ),
  "red_carpet": MinecraftMaterial(
    name: "Red Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/red_carpet.png",
  ),
  "red_concrete": MinecraftMaterial(
    name: "Red Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_concrete.png",
  ),
  "red_concrete_powder": MinecraftMaterial(
    name: "Red Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_concrete_powder.png",
  ),
  "red_dye": MinecraftMaterial(
    name: "Red Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/red_dye.png",
  ),
  "red_glazed_terracotta": MinecraftMaterial(
    name: "Red Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_glazed_terracotta.png",
  ),
  "red_harness": MinecraftMaterial(
    name: "Red Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/red_harness.png",
  ),
  "red_mushroom": MinecraftMaterial(
    name: "Red Mushroom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/red_mushroom.png",
  ),
  "red_mushroom_block": MinecraftMaterial(
    name: "Red Mushroom Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/red_mushroom_block.png",
  ),
  "red_nether_brick_slab": MinecraftMaterial(
    name: "Red Nether Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_nether_brick_slab.png",
  ),
  "red_nether_brick_stairs": MinecraftMaterial(
    name: "Red Nether Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_nether_brick_stairs.png",
  ),
  "red_nether_brick_wall": MinecraftMaterial(
    name: "Red Nether Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_nether_brick_wall.png",
  ),
  "red_nether_bricks": MinecraftMaterial(
    name: "Red Nether Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_nether_bricks.png",
  ),
  "red_sand": MinecraftMaterial(
    name: "Red Sand",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_sand.png",
  ),
  "red_sandstone": MinecraftMaterial(
    name: "Red Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_sandstone.png",
  ),
  "red_sandstone_slab": MinecraftMaterial(
    name: "Red Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_sandstone_slab.png",
  ),
  "red_sandstone_stairs": MinecraftMaterial(
    name: "Red Sandstone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_sandstone_stairs.png",
  ),
  "red_sandstone_wall": MinecraftMaterial(
    name: "Red Sandstone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_sandstone_wall.png",
  ),
  "red_shulker_box": MinecraftMaterial(
    name: "Red Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_shulker_box.png",
  ),
  "red_stained_glass": MinecraftMaterial(
    name: "Red Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_stained_glass.png",
  ),
  "red_stained_glass_pane": MinecraftMaterial(
    name: "Red Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_stained_glass_pane.png",
  ),
  "red_terracotta": MinecraftMaterial(
    name: "Red Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_terracotta.png",
  ),
  "red_tulip": MinecraftMaterial(
    name: "Red Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/red_tulip.png",
  ),
  "red_wool": MinecraftMaterial(
    name: "Red Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/red_wool.png",
  ),
  "redstone": MinecraftMaterial(
    name: "Redstone",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/redstone.png",
  ),
  "redstone_block": MinecraftMaterial(
    name: "Redstone Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/redstone_block.png",
  ),
  "redstone_lamp": MinecraftMaterial(
    name: "Redstone Lamp",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/redstone_lamp.png",
  ),
  "redstone_ore": MinecraftMaterial(
    name: "Redstone Ore",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.ore,
    ],
    icon: "assets/materials/redstone_ore.png",
  ),
  "redstone_torch": MinecraftMaterial(
    name: "Redstone Torch",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/redstone_torch.png",
  ),
  "reinforced_deepslate": MinecraftMaterial(
    name: "Reinforced Deepslate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/reinforced_deepslate.png",
  ),
  "repeater": MinecraftMaterial(
    name: "Repeater",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/repeater.png",
  ),
  "repeating_command_block": MinecraftMaterial(
    name: "Repeating Command Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/repeating_command_block.png",
  ),
  "resin_block": MinecraftMaterial(
    name: "Block of Resin",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_block.png",
  ),
  "resin_brick": MinecraftMaterial(
    name: "Resin Brick",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick.png",
  ),
  "resin_brick_slab": MinecraftMaterial(
    name: "Resin Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick_slab.png",
  ),
  "resin_brick_stairs": MinecraftMaterial(
    name: "Resin Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick_stairs.png",
  ),
  "resin_brick_wall": MinecraftMaterial(
    name: "Resin Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick_wall.png",
  ),
  "resin_bricks": MinecraftMaterial(
    name: "Resin Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_bricks.png",
  ),
  "resin_clump": MinecraftMaterial(
    name: "Resin Clump",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_clump.png",
  ),
  "respawn_anchor": MinecraftMaterial(
    name: "Respawn Anchor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/respawn_anchor.png",
  ),
  "rib_armor_trim_smithing_template": MinecraftMaterial(
    name: "Rib Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/rib_armor_trim_smithing_template.png",
  ),
  "rooted_dirt": MinecraftMaterial(
    name: "Rooted Dirt",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/rooted_dirt.png",
  ),
  "rose_bush": MinecraftMaterial(
    name: "Rose Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/rose_bush.png",
  ),
  "rotten_flesh": MinecraftMaterial(
    name: "Rotten Flesh",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/rotten_flesh.png",
  ),
  "saddle": MinecraftMaterial(
    name: "Saddle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/saddle.png",
  ),
  "salmon": MinecraftMaterial(
    name: "Salmon",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/salmon.png",
  ),
  "salmon_bucket": MinecraftMaterial(
    name: "Salmon Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/salmon_bucket.png",
  ),
  "salmon_spawn_egg": MinecraftMaterial(
    name: "Salmon Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/salmon_spawn_egg.png",
  ),
  "sand": MinecraftMaterial(
    name: "Sand",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sand.png",
  ),
  "sandstone": MinecraftMaterial(
    name: "Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sandstone.png",
  ),
  "sandstone_slab": MinecraftMaterial(
    name: "Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sandstone_slab.png",
  ),
  "sandstone_stairs": MinecraftMaterial(
    name: "Sandstone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sandstone_stairs.png",
  ),
  "sandstone_wall": MinecraftMaterial(
    name: "Sandstone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sandstone_wall.png",
  ),
  "scaffolding": MinecraftMaterial(
    name: "Scaffolding",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/scaffolding.png",
  ),
  "scrape_pottery_sherd": MinecraftMaterial(
    name: "Scrape Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/scrape_pottery_sherd.png",
  ),
  "sculk": MinecraftMaterial(
    name: "Sculk",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk.png",
  ),
  "sculk_catalyst": MinecraftMaterial(
    name: "Sculk Catalyst",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk_catalyst.png",
  ),
  "sculk_sensor": MinecraftMaterial(
    name: "Sculk Sensor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk_sensor.png",
  ),
  "sculk_shrieker": MinecraftMaterial(
    name: "Sculk Shrieker",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk_shrieker.png",
  ),
  "sculk_vein": MinecraftMaterial(
    name: "Sculk Vein",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk_vein.png",
  ),
  "sea_lantern": MinecraftMaterial(
    name: "Sea Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sea_lantern.png",
  ),
  "sea_pickle": MinecraftMaterial(
    name: "Sea Pickle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/sea_pickle.png",
  ),
  "seagrass": MinecraftMaterial(
    name: "Seagrass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/seagrass.png",
  ),
  "sentry_armor_trim_smithing_template": MinecraftMaterial(
    name: "Sentry Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/sentry_armor_trim_smithing_template.png",
  ),
  "shaper_armor_trim_smithing_template": MinecraftMaterial(
    name: "Shaper Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/shaper_armor_trim_smithing_template.png",
  ),
  "sheaf_pottery_sherd": MinecraftMaterial(
    name: "Sheaf Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/sheaf_pottery_sherd.png",
  ),
  "shears": MinecraftMaterial(
    name: "Shears",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/shears.png",
  ),
  "sheep_spawn_egg": MinecraftMaterial(
    name: "Sheep Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/sheep_spawn_egg.png",
  ),
  "shelter_pottery_sherd": MinecraftMaterial(
    name: "Shelter Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/shelter_pottery_sherd.png",
  ),
  "shield": MinecraftMaterial(
    name: "Shield",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/shield.png",
  ),
  "short_dry_grass": MinecraftMaterial(
    name: "Short Dry Grass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/short_dry_grass.png",
  ),
  "short_grass": MinecraftMaterial(
    name: "Short Grass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/short_grass.png",
  ),
  "shroomlight": MinecraftMaterial(
    name: "Shroomlight",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/shroomlight.png",
  ),
  "shulker_box": MinecraftMaterial(
    name: "Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/shulker_box.png",
  ),
  "shulker_shell": MinecraftMaterial(
    name: "Shulker Shell",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/shulker_shell.png",
  ),
  "shulker_spawn_egg": MinecraftMaterial(
    name: "Shulker Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/shulker_spawn_egg.png",
  ),
  "silence_armor_trim_smithing_template": MinecraftMaterial(
    name: "Silence Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/silence_armor_trim_smithing_template.png",
  ),
  "silverfish_spawn_egg": MinecraftMaterial(
    name: "Silverfish Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/silverfish_spawn_egg.png",
  ),
  "skeleton_horse_spawn_egg": MinecraftMaterial(
    name: "Skeleton Horse Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/skeleton_horse_spawn_egg.png",
  ),
  "skeleton_skull": MinecraftMaterial(
    name: "Skeleton Skull",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/skeleton_skull.png",
  ),
  "skeleton_spawn_egg": MinecraftMaterial(
    name: "Skeleton Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/skeleton_spawn_egg.png",
  ),
  "skull_banner_pattern": MinecraftMaterial(
    name: "Skull Banner Pattern",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/skull_banner_pattern.png",
  ),
  "skull_pottery_sherd": MinecraftMaterial(
    name: "Skull Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/skull_pottery_sherd.png",
  ),
  "slime_ball": MinecraftMaterial(
    name: "Slime Ball",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/slime_ball.png",
  ),
  "slime_block": MinecraftMaterial(
    name: "Slime Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/slime_block.png",
  ),
  "slime_spawn_egg": MinecraftMaterial(
    name: "Slime Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/slime_spawn_egg.png",
  ),
  "small_amethyst_bud": MinecraftMaterial(
    name: "Small Amethyst Bud",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/small_amethyst_bud.png",
  ),
  "small_dripleaf": MinecraftMaterial(
    name: "Small Dripleaf",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/small_dripleaf.png",
  ),
  "smithing_table": MinecraftMaterial(
    name: "Smithing Table",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/smithing_table.png",
  ),
  "smoker": MinecraftMaterial(
    name: "Smoker",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smoker.png",
  ),
  "smooth_basalt": MinecraftMaterial(
    name: "Smooth Basalt",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_basalt.png",
  ),
  "smooth_quartz": MinecraftMaterial(
    name: "Smooth Quartz",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_quartz.png",
  ),
  "smooth_quartz_slab": MinecraftMaterial(
    name: "Smooth Quartz Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_quartz_slab.png",
  ),
  "smooth_quartz_stairs": MinecraftMaterial(
    name: "Smooth Quartz Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_quartz_stairs.png",
  ),
  "smooth_red_sandstone": MinecraftMaterial(
    name: "Smooth Red Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_red_sandstone.png",
  ),
  "smooth_red_sandstone_slab": MinecraftMaterial(
    name: "Smooth Red Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_red_sandstone_slab.png",
  ),
  "smooth_red_sandstone_stairs": MinecraftMaterial(
    name: "Smooth Red Sandstone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_red_sandstone_stairs.png",
  ),
  "smooth_sandstone": MinecraftMaterial(
    name: "Smooth Sandstone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_sandstone.png",
  ),
  "smooth_sandstone_slab": MinecraftMaterial(
    name: "Smooth Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_sandstone_slab.png",
  ),
  "smooth_sandstone_stairs": MinecraftMaterial(
    name: "Smooth Sandstone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_sandstone_stairs.png",
  ),
  "smooth_stone": MinecraftMaterial(
    name: "Smooth Stone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_stone.png",
  ),
  "smooth_stone_slab": MinecraftMaterial(
    name: "Smooth Stone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_stone_slab.png",
  ),
  "sniffer_egg": MinecraftMaterial(
    name: "Sniffer Egg",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/sniffer_egg.png",
  ),
  "sniffer_spawn_egg": MinecraftMaterial(
    name: "Sniffer Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/sniffer_spawn_egg.png",
  ),
  "snort_pottery_sherd": MinecraftMaterial(
    name: "Snort Pottery Sherd",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/snort_pottery_sherd.png",
  ),
  "snout_armor_trim_smithing_template": MinecraftMaterial(
    name: "Snout Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/snout_armor_trim_smithing_template.png",
  ),
  "snow": MinecraftMaterial(
    name: "Snow",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/snow.png",
  ),
  "snow_block": MinecraftMaterial(
    name: "Snow Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/snow_block.png",
  ),
  "snow_golem_spawn_egg": MinecraftMaterial(
    name: "Snow Golem Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/snow_golem_spawn_egg.png",
  ),
  "snowball": MinecraftMaterial(
    name: "Snowball",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/snowball.png",
  ),
  "soul_campfire": MinecraftMaterial(
    name: "Soul Campfire",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/soul_campfire.png",
  ),
  "soul_lantern": MinecraftMaterial(
    name: "Soul Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/soul_lantern.png",
  ),
  "soul_sand": MinecraftMaterial(
    name: "Soul Sand",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/soul_sand.png",
  ),
  "soul_soil": MinecraftMaterial(
    name: "Soul Soil",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/soul_soil.png",
  ),
  "soul_torch": MinecraftMaterial(
    name: "Soul Torch",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/soul_torch.png",
  ),
  "soul_wall_torch": MinecraftMaterial(
    name: "Soul Wall Torch",
    properties: [
      MaterialProperty.block,
    ],
    icon: "assets/materials/soul_wall_torch.png",
  ),
  "spawner": MinecraftMaterial(
    name: "Spawner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/spawner.png",
  ),
  "spectral_arrow": MinecraftMaterial(
    name: "Spectral Arrow",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/spectral_arrow.png",
  ),
  "spider_eye": MinecraftMaterial(
    name: "Spider Eye",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/spider_eye.png",
  ),
  "spider_spawn_egg": MinecraftMaterial(
    name: "Spider Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/spider_spawn_egg.png",
  ),
  "spire_armor_trim_smithing_template": MinecraftMaterial(
    name: "Spire Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/spire_armor_trim_smithing_template.png",
  ),
  "splash_potion": MinecraftMaterial(
    name: "Splash Potion",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/splash_potion.png",
  ),
  "sponge": MinecraftMaterial(
    name: "Sponge",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sponge.png",
  ),
  "spore_blossom": MinecraftMaterial(
    name: "Spore Blossom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/spore_blossom.png",
  ),
  "spruce_boat": MinecraftMaterial(
    name: "Spruce Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/spruce_boat.png",
  ),
  "spruce_button": MinecraftMaterial(
    name: "Spruce Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/spruce_button.png",
  ),
  "spruce_chest_boat": MinecraftMaterial(
    name: "Spruce Chest Boat",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/spruce_chest_boat.png",
  ),
  "spruce_door": MinecraftMaterial(
    name: "Spruce Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_door.png",
  ),
  "spruce_fence": MinecraftMaterial(
    name: "Spruce Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_fence.png",
  ),
  "spruce_fence_gate": MinecraftMaterial(
    name: "Spruce Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_fence_gate.png",
  ),
  "spruce_hanging_sign": MinecraftMaterial(
    name: "Spruce Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/spruce_hanging_sign.png",
  ),
  "spruce_leaves": MinecraftMaterial(
    name: "Spruce Leaves",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_leaves.png",
  ),
  "spruce_log": MinecraftMaterial(
    name: "Spruce Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_log.png",
  ),
  "spruce_planks": MinecraftMaterial(
    name: "Spruce Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_planks.png",
  ),
  "spruce_pressure_plate": MinecraftMaterial(
    name: "Spruce Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_pressure_plate.png",
  ),
  "spruce_sapling": MinecraftMaterial(
    name: "Spruce Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/spruce_sapling.png",
  ),
  "spruce_sign": MinecraftMaterial(
    name: "Spruce Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_sign.png",
  ),
  "spruce_slab": MinecraftMaterial(
    name: "Spruce Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_slab.png",
  ),
  "spruce_stairs": MinecraftMaterial(
    name: "Spruce Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_stairs.png",
  ),
  "spruce_trapdoor": MinecraftMaterial(
    name: "Spruce Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_trapdoor.png",
  ),
  "spruce_wood": MinecraftMaterial(
    name: "Spruce Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_wood.png",
  ),
  "spyglass": MinecraftMaterial(
    name: "Spyglass",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/spyglass.png",
  ),
  "squid_spawn_egg": MinecraftMaterial(
    name: "Squid Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/squid_spawn_egg.png",
  ),
  "stick": MinecraftMaterial(
    name: "Stick",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/stick.png",
  ),
  "sticky_piston": MinecraftMaterial(
    name: "Sticky Piston",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sticky_piston.png",
  ),
  "stone": MinecraftMaterial(
    name: "Stone",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone.png",
  ),
  "stone_axe": MinecraftMaterial(
    name: "Stone Axe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/stone_axe.png",
  ),
  "stone_brick_slab": MinecraftMaterial(
    name: "Stone Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_brick_slab.png",
  ),
  "stone_brick_stairs": MinecraftMaterial(
    name: "Stone Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_brick_stairs.png",
  ),
  "stone_brick_wall": MinecraftMaterial(
    name: "Stone Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_brick_wall.png",
  ),
  "stone_bricks": MinecraftMaterial(
    name: "Stone Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_bricks.png",
  ),
  "stone_button": MinecraftMaterial(
    name: "Stone Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/stone_button.png",
  ),
  "stone_hoe": MinecraftMaterial(
    name: "Stone Hoe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/stone_hoe.png",
  ),
  "stone_pickaxe": MinecraftMaterial(
    name: "Stone Pickaxe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/stone_pickaxe.png",
  ),
  "stone_pressure_plate": MinecraftMaterial(
    name: "Stone Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_pressure_plate.png",
  ),
  "stone_shovel": MinecraftMaterial(
    name: "Stone Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/stone_shovel.png",
  ),
  "stone_slab": MinecraftMaterial(
    name: "Stone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_slab.png",
  ),
  "stone_stairs": MinecraftMaterial(
    name: "Stone Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_stairs.png",
  ),
  "stone_sword": MinecraftMaterial(
    name: "Stone Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/stone_sword.png",
  ),
  "stonecutter": MinecraftMaterial(
    name: "Stonecutter",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stonecutter.png",
  ),
  "stray_spawn_egg": MinecraftMaterial(
    name: "Stray Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/stray_spawn_egg.png",
  ),
  "strider_spawn_egg": MinecraftMaterial(
    name: "Strider Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/strider_spawn_egg.png",
  ),
  "string": MinecraftMaterial(
    name: "String",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/string.png",
  ),
  "stripped_acacia_log": MinecraftMaterial(
    name: "Stripped Acacia Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_acacia_log.png",
  ),
  "stripped_acacia_wood": MinecraftMaterial(
    name: "Stripped Acacia Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_acacia_wood.png",
  ),
  "stripped_bamboo_block": MinecraftMaterial(
    name: "Block of Stripped Bamboo",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/stripped_bamboo_block.png",
  ),
  "stripped_birch_log": MinecraftMaterial(
    name: "Stripped Birch Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_birch_log.png",
  ),
  "stripped_birch_wood": MinecraftMaterial(
    name: "Stripped Birch Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_birch_wood.png",
  ),
  "stripped_cherry_log": MinecraftMaterial(
    name: "Stripped Cherry Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/stripped_cherry_log.png",
  ),
  "stripped_cherry_wood": MinecraftMaterial(
    name: "Stripped Cherry Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/stripped_cherry_wood.png",
  ),
  "stripped_crimson_hyphae": MinecraftMaterial(
    name: "Stripped Crimson Hyphae",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stripped_crimson_hyphae.png",
  ),
  "stripped_crimson_stem": MinecraftMaterial(
    name: "Stripped Crimson Stem",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stripped_crimson_stem.png",
  ),
  "stripped_dark_oak_log": MinecraftMaterial(
    name: "Stripped Dark Oak Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_dark_oak_log.png",
  ),
  "stripped_dark_oak_wood": MinecraftMaterial(
    name: "Stripped Dark Oak Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_dark_oak_wood.png",
  ),
  "stripped_jungle_log": MinecraftMaterial(
    name: "Stripped Jungle Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_jungle_log.png",
  ),
  "stripped_jungle_wood": MinecraftMaterial(
    name: "Stripped Jungle Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_jungle_wood.png",
  ),
  "stripped_mangrove_log": MinecraftMaterial(
    name: "Stripped Mangrove Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_mangrove_log.png",
  ),
  "stripped_mangrove_wood": MinecraftMaterial(
    name: "Stripped Mangrove Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_mangrove_wood.png",
  ),
  "stripped_oak_log": MinecraftMaterial(
    name: "Stripped Oak Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_oak_log.png",
  ),
  "stripped_oak_wood": MinecraftMaterial(
    name: "Stripped Oak Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_oak_wood.png",
  ),
  "stripped_pale_oak_log": MinecraftMaterial(
    name: "Stripped Pale Oak Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/stripped_pale_oak_log.png",
  ),
  "stripped_pale_oak_wood": MinecraftMaterial(
    name: "Stripped Pale Oak Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/stripped_pale_oak_wood.png",
  ),
  "stripped_spruce_log": MinecraftMaterial(
    name: "Stripped Spruce Log",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_spruce_log.png",
  ),
  "stripped_spruce_wood": MinecraftMaterial(
    name: "Stripped Spruce Wood",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/stripped_spruce_wood.png",
  ),
  "stripped_warped_hyphae": MinecraftMaterial(
    name: "Stripped Warped Hyphae",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stripped_warped_hyphae.png",
  ),
  "stripped_warped_stem": MinecraftMaterial(
    name: "Stripped Warped Stem",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stripped_warped_stem.png",
  ),
  "structure_block": MinecraftMaterial(
    name: "Structure Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/structure_block.png",
  ),
  "structure_void": MinecraftMaterial(
    name: "Structure Void",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/structure_void.png",
  ),
  "sugar": MinecraftMaterial(
    name: "Sugar",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/sugar.png",
  ),
  "sugar_cane": MinecraftMaterial(
    name: "Sugar Cane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/sugar_cane.png",
  ),
  "sunflower": MinecraftMaterial(
    name: "Sunflower",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/sunflower.png",
  ),
  "suspicious_gravel": MinecraftMaterial(
    name: "Suspicious Gravel",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/suspicious_gravel.png",
  ),
  "suspicious_sand": MinecraftMaterial(
    name: "Suspicious Sand",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/suspicious_sand.png",
  ),
  "suspicious_stew": MinecraftMaterial(
    name: "Suspicious Stew",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/suspicious_stew.png",
  ),
  "sweet_berries": MinecraftMaterial(
    name: "Sweet Berries",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/sweet_berries.png",
  ),
  "tadpole_bucket": MinecraftMaterial(
    name: "Tadpole Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/tadpole_bucket.png",
  ),
  "tadpole_spawn_egg": MinecraftMaterial(
    name: "Tadpole Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/tadpole_spawn_egg.png",
  ),
  "tall_dry_grass": MinecraftMaterial(
    name: "Tall Dry Grass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tall_dry_grass.png",
  ),
  "tall_grass": MinecraftMaterial(
    name: "Tall Grass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/tall_grass.png",
  ),
  "target": MinecraftMaterial(
    name: "Target",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/target.png",
  ),
  "terracotta": MinecraftMaterial(
    name: "Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/terracotta.png",
  ),
  "test_block": MinecraftMaterial(
    name: "Test Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/test_block.png",
  ),
  "test_instance_block": MinecraftMaterial(
    name: "Test Instance Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/test_instance_block.png",
  ),
  "tide_armor_trim_smithing_template": MinecraftMaterial(
    name: "Tide Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/tide_armor_trim_smithing_template.png",
  ),
  "tinted_glass": MinecraftMaterial(
    name: "Tinted Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/tinted_glass.png",
  ),
  "tipped_arrow": MinecraftMaterial(
    name: "Tipped Arrow",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/tipped_arrow.png",
  ),
  "tnt": MinecraftMaterial(
    name: "Tnt",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/tnt.png",
  ),
  "tnt_minecart": MinecraftMaterial(
    name: "Tnt Minecart",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/tnt_minecart.png",
  ),
  "torch": MinecraftMaterial(
    name: "Torch",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/torch.png",
  ),
  "torchflower": MinecraftMaterial(
    name: "Torchflower",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/torchflower.png",
  ),
  "torchflower_seeds": MinecraftMaterial(
    name: "Torchflower Seeds",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/torchflower_seeds.png",
  ),
  "totem_of_undying": MinecraftMaterial(
    name: "Totem Of Undying",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/totem_of_undying.png",
  ),
  "trader_llama_spawn_egg": MinecraftMaterial(
    name: "Trader Llama Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/trader_llama_spawn_egg.png",
  ),
  "trapped_chest": MinecraftMaterial(
    name: "Trapped Chest",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/trapped_chest.png",
  ),
  "trial_key": MinecraftMaterial(
    name: "Trial Key",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/trial_key.png",
  ),
  "trial_spawner": MinecraftMaterial(
    name: "Trial Spawner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/trial_spawner.png",
  ),
  "trident": MinecraftMaterial(
    name: "Trident",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/trident.png",
  ),
  "tripwire_hook": MinecraftMaterial(
    name: "Tripwire Hook",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/tripwire_hook.png",
  ),
  "tropical_fish": MinecraftMaterial(
    name: "Tropical Fish",
    properties: [
      MaterialProperty.item,
      MaterialProperty.edible,
    ],
    icon: "assets/materials/tropical_fish.png",
  ),
  "tropical_fish_bucket": MinecraftMaterial(
    name: "Tropical Fish Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/tropical_fish_bucket.png",
  ),
  "tropical_fish_spawn_egg": MinecraftMaterial(
    name: "Tropical Fish Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/tropical_fish_spawn_egg.png",
  ),
  "tube_coral": MinecraftMaterial(
    name: "Tube Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tube_coral.png",
  ),
  "tube_coral_block": MinecraftMaterial(
    name: "Tube Coral Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/tube_coral_block.png",
  ),
  "tube_coral_fan": MinecraftMaterial(
    name: "Tube Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tube_coral_fan.png",
  ),
  "tuff": MinecraftMaterial(
    name: "Tuff",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/tuff.png",
  ),
  "tuff_brick_slab": MinecraftMaterial(
    name: "Tuff Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tuff_brick_slab.png",
  ),
  "tuff_brick_stairs": MinecraftMaterial(
    name: "Tuff Brick Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tuff_brick_stairs.png",
  ),
  "tuff_brick_wall": MinecraftMaterial(
    name: "Tuff Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tuff_brick_wall.png",
  ),
  "tuff_bricks": MinecraftMaterial(
    name: "Tuff Bricks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tuff_bricks.png",
  ),
  "tuff_slab": MinecraftMaterial(
    name: "Tuff Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tuff_slab.png",
  ),
  "tuff_stairs": MinecraftMaterial(
    name: "Tuff Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tuff_stairs.png",
  ),
  "tuff_wall": MinecraftMaterial(
    name: "Tuff Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tuff_wall.png",
  ),
  "turtle_egg": MinecraftMaterial(
    name: "Turtle Egg",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/turtle_egg.png",
  ),
  "turtle_helmet": MinecraftMaterial(
    name: "Turtle Helmet",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/turtle_helmet.png",
  ),
  "turtle_scute": MinecraftMaterial(
    name: "Turtle Scute",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/turtle_scute.png",
  ),
  "turtle_spawn_egg": MinecraftMaterial(
    name: "Turtle Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/turtle_spawn_egg.png",
  ),
  "twisting_vines": MinecraftMaterial(
    name: "Twisting Vines",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/twisting_vines.png",
  ),
  "vault": MinecraftMaterial(
    name: "Vault",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/vault.png",
  ),
  "verdant_froglight": MinecraftMaterial(
    name: "Verdant Froglight",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/verdant_froglight.png",
  ),
  "vex_armor_trim_smithing_template": MinecraftMaterial(
    name: "Vex Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/vex_armor_trim_smithing_template.png",
  ),
  "vex_spawn_egg": MinecraftMaterial(
    name: "Vex Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/vex_spawn_egg.png",
  ),
  "villager_spawn_egg": MinecraftMaterial(
    name: "Villager Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/villager_spawn_egg.png",
  ),
  "vindicator_spawn_egg": MinecraftMaterial(
    name: "Vindicator Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/vindicator_spawn_egg.png",
  ),
  "vine": MinecraftMaterial(
    name: "Vine",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/vine.png",
  ),
  "wandering_trader_spawn_egg": MinecraftMaterial(
    name: "Wandering Trader Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wandering_trader_spawn_egg.png",
  ),
  "ward_armor_trim_smithing_template": MinecraftMaterial(
    name: "Ward Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/ward_armor_trim_smithing_template.png",
  ),
  "warden_spawn_egg": MinecraftMaterial(
    name: "Warden Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/warden_spawn_egg.png",
  ),
  "warped_button": MinecraftMaterial(
    name: "Warped Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/warped_button.png",
  ),
  "warped_door": MinecraftMaterial(
    name: "Warped Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_door.png",
  ),
  "warped_fence": MinecraftMaterial(
    name: "Warped Fence",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_fence.png",
  ),
  "warped_fence_gate": MinecraftMaterial(
    name: "Warped Fence Gate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_fence_gate.png",
  ),
  "warped_fungus": MinecraftMaterial(
    name: "Warped Fungus",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/warped_fungus.png",
  ),
  "warped_fungus_on_a_stick": MinecraftMaterial(
    name: "Warped Fungus On A Stick",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/warped_fungus_on_a_stick.png",
  ),
  "warped_hanging_sign": MinecraftMaterial(
    name: "Warped Hanging Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/warped_hanging_sign.png",
  ),
  "warped_hyphae": MinecraftMaterial(
    name: "Warped Hyphae",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_hyphae.png",
  ),
  "warped_nylium": MinecraftMaterial(
    name: "Warped Nylium",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_nylium.png",
  ),
  "warped_planks": MinecraftMaterial(
    name: "Warped Planks",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_planks.png",
  ),
  "warped_pressure_plate": MinecraftMaterial(
    name: "Warped Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_pressure_plate.png",
  ),
  "warped_roots": MinecraftMaterial(
    name: "Warped Roots",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/warped_roots.png",
  ),
  "warped_sign": MinecraftMaterial(
    name: "Warped Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_sign.png",
  ),
  "warped_slab": MinecraftMaterial(
    name: "Warped Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_slab.png",
  ),
  "warped_stairs": MinecraftMaterial(
    name: "Warped Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_stairs.png",
  ),
  "warped_stem": MinecraftMaterial(
    name: "Warped Stem",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_stem.png",
  ),
  "warped_trapdoor": MinecraftMaterial(
    name: "Warped Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_trapdoor.png",
  ),
  "warped_wart_block": MinecraftMaterial(
    name: "Warped Wart Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_wart_block.png",
  ),
  "water_bucket": MinecraftMaterial(
    name: "Water Bucket",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/water_bucket.png",
  ),
  "waxed_chiseled_copper": MinecraftMaterial(
    name: "Waxed Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_chiseled_copper.png",
  ),
  "waxed_copper_block": MinecraftMaterial(
    name: "Waxed Copper Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_copper_block.png",
  ),
  "waxed_copper_bulb": MinecraftMaterial(
    name: "Waxed Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_bulb.png",
  ),
  "waxed_copper_door": MinecraftMaterial(
    name: "Waxed Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_door.png",
  ),
  "waxed_copper_grate": MinecraftMaterial(
    name: "Waxed Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_grate.png",
  ),
  "waxed_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_trapdoor.png",
  ),
  "waxed_cut_copper": MinecraftMaterial(
    name: "Waxed Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_cut_copper.png",
  ),
  "waxed_cut_copper_slab": MinecraftMaterial(
    name: "Waxed Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_cut_copper_slab.png",
  ),
  "waxed_cut_copper_stairs": MinecraftMaterial(
    name: "Waxed Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_cut_copper_stairs.png",
  ),
  "waxed_exposed_chiseled_copper": MinecraftMaterial(
    name: "Waxed Exposed Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_chiseled_copper.png",
  ),
  "waxed_exposed_copper": MinecraftMaterial(
    name: "Waxed Exposed Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_exposed_copper.png",
  ),
  "waxed_exposed_copper_bulb": MinecraftMaterial(
    name: "Waxed Exposed Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_bulb.png",
  ),
  "waxed_exposed_copper_door": MinecraftMaterial(
    name: "Waxed Exposed Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_door.png",
  ),
  "waxed_exposed_copper_grate": MinecraftMaterial(
    name: "Waxed Exposed Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_grate.png",
  ),
  "waxed_exposed_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Exposed Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_trapdoor.png",
  ),
  "waxed_exposed_copper_lantern": MinecraftMaterial(
    name: "Waxed Exposed Copper Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_lantern.png",
  ),
  "waxed_exposed_cut_copper": MinecraftMaterial(
    name: "Waxed Exposed Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_exposed_cut_copper.png",
  ),
  "waxed_exposed_cut_copper_slab": MinecraftMaterial(
    name: "Waxed Exposed Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_exposed_cut_copper_slab.png",
  ),
  "waxed_exposed_cut_copper_stairs": MinecraftMaterial(
    name: "Waxed Exposed Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_exposed_cut_copper_stairs.png",
  ),
  "waxed_oxidized_chiseled_copper": MinecraftMaterial(
    name: "Waxed Oxidized Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_chiseled_copper.png",
  ),
  "waxed_oxidized_copper": MinecraftMaterial(
    name: "Waxed Oxidized Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_oxidized_copper.png",
  ),
  "waxed_oxidized_copper_bulb": MinecraftMaterial(
    name: "Waxed Oxidized Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_bulb.png",
  ),
  "waxed_oxidized_copper_door": MinecraftMaterial(
    name: "Waxed Oxidized Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_door.png",
  ),
  "waxed_oxidized_copper_grate": MinecraftMaterial(
    name: "Waxed Oxidized Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_grate.png",
  ),
  "waxed_oxidized_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Oxidized Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_trapdoor.png",
  ),
  "waxed_oxidized_copper_lantern": MinecraftMaterial(
    name: "Waxed Oxidized Copper Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_lantern.png",
  ),
  "waxed_oxidized_cut_copper": MinecraftMaterial(
    name: "Waxed Oxidized Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_oxidized_cut_copper.png",
  ),
  "waxed_oxidized_cut_copper_slab": MinecraftMaterial(
    name: "Waxed Oxidized Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_oxidized_cut_copper_slab.png",
  ),
  "waxed_oxidized_cut_copper_stairs": MinecraftMaterial(
    name: "Waxed Oxidized Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_oxidized_cut_copper_stairs.png",
  ),
  "waxed_weathered_chiseled_copper": MinecraftMaterial(
    name: "Waxed Weathered Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_chiseled_copper.png",
  ),
  "waxed_weathered_copper": MinecraftMaterial(
    name: "Waxed Weathered Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_weathered_copper.png",
  ),
  "waxed_weathered_copper_bulb": MinecraftMaterial(
    name: "Waxed Weathered Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_bulb.png",
  ),
  "waxed_weathered_copper_door": MinecraftMaterial(
    name: "Waxed Weathered Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_door.png",
  ),
  "waxed_weathered_copper_grate": MinecraftMaterial(
    name: "Waxed Weathered Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_grate.png",
  ),
  "waxed_weathered_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Weathered Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_trapdoor.png",
  ),
  "waxed_weathered_copper_lantern": MinecraftMaterial(
    name: "Waxed Weathered Copper Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_lantern.png",
  ),
  "waxed_weathered_cut_copper": MinecraftMaterial(
    name: "Waxed Weathered Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_weathered_cut_copper.png",
  ),
  "waxed_weathered_cut_copper_slab": MinecraftMaterial(
    name: "Waxed Weathered Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_weathered_cut_copper_slab.png",
  ),
  "waxed_weathered_cut_copper_stairs": MinecraftMaterial(
    name: "Waxed Weathered Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_weathered_cut_copper_stairs.png",
  ),
  "wayfinder_armor_trim_smithing_template": MinecraftMaterial(
    name: "Wayfinder Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wayfinder_armor_trim_smithing_template.png",
  ),
  "weathered_chiseled_copper": MinecraftMaterial(
    name: "Weathered Chiseled Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_chiseled_copper.png",
  ),
  "weathered_copper": MinecraftMaterial(
    name: "Weathered Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/weathered_copper.png",
  ),
  "weathered_copper_bulb": MinecraftMaterial(
    name: "Weathered Copper Bulb",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_bulb.png",
  ),
  "weathered_copper_door": MinecraftMaterial(
    name: "Weathered Copper Door",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_door.png",
  ),
  "weathered_copper_grate": MinecraftMaterial(
    name: "Weathered Copper Grate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_grate.png",
  ),
  "weathered_copper_trapdoor": MinecraftMaterial(
    name: "Weathered Copper Trapdoor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_trapdoor.png",
  ),
  "weathered_copper_lantern": MinecraftMaterial(
    name: "Weathered Copper Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_lantern.png",
  ),
  "weathered_cut_copper": MinecraftMaterial(
    name: "Weathered Cut Copper",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/weathered_cut_copper.png",
  ),
  "weathered_cut_copper_slab": MinecraftMaterial(
    name: "Weathered Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/weathered_cut_copper_slab.png",
  ),
  "weathered_cut_copper_stairs": MinecraftMaterial(
    name: "Weathered Cut Copper Stairs",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/weathered_cut_copper_stairs.png",
  ),
  "weeping_vines": MinecraftMaterial(
    name: "Weeping Vines",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weeping_vines.png",
  ),
  "weeping_vines_plant": MinecraftMaterial(
    name: "Weeping Vines Plant",
    properties: [
      MaterialProperty.block,
    ],
    icon: "assets/materials/weeping_vines_plant.webp",
  ),
  "wet_sponge": MinecraftMaterial(
    name: "Wet Sponge",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/wet_sponge.png",
  ),
  "wheat": MinecraftMaterial(
    name: "Wheat",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/wheat.png",
  ),
  "wheat_seeds": MinecraftMaterial(
    name: "Wheat Seeds",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wheat_seeds.png",
  ),
  "white_banner": MinecraftMaterial(
    name: "White Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/white_banner.png",
  ),
  "white_bed": MinecraftMaterial(
    name: "White Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/white_bed.png",
  ),
  "white_bundle": MinecraftMaterial(
    name: "White Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/white_bundle.png",
  ),
  "white_candle": MinecraftMaterial(
    name: "White Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/white_candle.png",
  ),
  "white_carpet": MinecraftMaterial(
    name: "White Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/white_carpet.png",
  ),
  "white_concrete": MinecraftMaterial(
    name: "White Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_concrete.png",
  ),
  "white_concrete_powder": MinecraftMaterial(
    name: "White Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_concrete_powder.png",
  ),
  "white_dye": MinecraftMaterial(
    name: "White Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/white_dye.png",
  ),
  "white_glazed_terracotta": MinecraftMaterial(
    name: "White Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_glazed_terracotta.png",
  ),
  "white_harness": MinecraftMaterial(
    name: "White Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/white_harness.png",
  ),
  "white_shulker_box": MinecraftMaterial(
    name: "White Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_shulker_box.png",
  ),
  "white_stained_glass": MinecraftMaterial(
    name: "White Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_stained_glass.png",
  ),
  "white_stained_glass_pane": MinecraftMaterial(
    name: "White Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_stained_glass_pane.png",
  ),
  "white_terracotta": MinecraftMaterial(
    name: "White Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_terracotta.png",
  ),
  "white_tulip": MinecraftMaterial(
    name: "White Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/white_tulip.png",
  ),
  "white_wool": MinecraftMaterial(
    name: "White Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/white_wool.png",
  ),
  "wild_armor_trim_smithing_template": MinecraftMaterial(
    name: "Wild Armor Trim",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wild_armor_trim_smithing_template.png",
  ),
  "wildflowers": MinecraftMaterial(
    name: "Wildflowers",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/wildflowers.png",
  ),
  "wind_charge": MinecraftMaterial(
    name: "Wind Charge",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wind_charge.png",
  ),
  "witch_spawn_egg": MinecraftMaterial(
    name: "Witch Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/witch_spawn_egg.png",
  ),
  "wither_rose": MinecraftMaterial(
    name: "Wither Rose",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/wither_rose.png",
  ),
  "wither_skeleton_skull": MinecraftMaterial(
    name: "Wither Skeleton Skull",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/wither_skeleton_skull.png",
  ),
  "wither_skeleton_spawn_egg": MinecraftMaterial(
    name: "Wither Skeleton Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wither_skeleton_spawn_egg.png",
  ),
  "wither_spawn_egg": MinecraftMaterial(
    name: "Wither Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wither_spawn_egg.png",
  ),
  "wolf_armor": MinecraftMaterial(
    name: "Wolf Armor",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wolf_armor.png",
  ),
  "wolf_spawn_egg": MinecraftMaterial(
    name: "Wolf Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/wolf_spawn_egg.png",
  ),
  "wooden_axe": MinecraftMaterial(
    name: "Wooden Axe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/wooden_axe.png",
  ),
  "wooden_hoe": MinecraftMaterial(
    name: "Wooden Hoe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/wooden_hoe.png",
  ),
  "wooden_pickaxe": MinecraftMaterial(
    name: "Wooden Pickaxe",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/wooden_pickaxe.png",
  ),
  "wooden_shovel": MinecraftMaterial(
    name: "Wooden Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/wooden_shovel.png",
  ),
  "wooden_sword": MinecraftMaterial(
    name: "Wooden Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/wooden_sword.png",
  ),
  "writable_book": MinecraftMaterial(
    name: "Writable Book",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/writable_book.png",
  ),
  "written_book": MinecraftMaterial(
    name: "Written Book",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/written_book.png",
  ),
  "yellow_banner": MinecraftMaterial(
    name: "Yellow Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/yellow_banner.png",
  ),
  "yellow_bed": MinecraftMaterial(
    name: "Yellow Bed",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/yellow_bed.png",
  ),
  "yellow_bundle": MinecraftMaterial(
    name: "Yellow Bundle",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/yellow_bundle.png",
  ),
  "yellow_candle": MinecraftMaterial(
    name: "Yellow Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/yellow_candle.png",
  ),
  "yellow_carpet": MinecraftMaterial(
    name: "Yellow Carpet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/yellow_carpet.png",
  ),
  "yellow_concrete": MinecraftMaterial(
    name: "Yellow Concrete",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_concrete.png",
  ),
  "yellow_concrete_powder": MinecraftMaterial(
    name: "Yellow Concrete Powder",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_concrete_powder.png",
  ),
  "yellow_dye": MinecraftMaterial(
    name: "Yellow Dye",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/yellow_dye.png",
  ),
  "yellow_glazed_terracotta": MinecraftMaterial(
    name: "Yellow Glazed Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_glazed_terracotta.png",
  ),
  "yellow_harness": MinecraftMaterial(
    name: "Yellow Harness",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/yellow_harness.png",
  ),
  "yellow_shulker_box": MinecraftMaterial(
    name: "Yellow Shulker Box",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_shulker_box.png",
  ),
  "yellow_stained_glass": MinecraftMaterial(
    name: "Yellow Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_stained_glass.png",
  ),
  "yellow_stained_glass_pane": MinecraftMaterial(
    name: "Yellow Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_stained_glass_pane.png",
  ),
  "yellow_terracotta": MinecraftMaterial(
    name: "Yellow Terracotta",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.occluding,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_terracotta.png",
  ),
  "yellow_wool": MinecraftMaterial(
    name: "Yellow Wool",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.occluding,
      MaterialProperty.solid,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/yellow_wool.png",
  ),
  "zoglin_spawn_egg": MinecraftMaterial(
    name: "Zoglin Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/zoglin_spawn_egg.png",
  ),
  "zombie_head": MinecraftMaterial(
    name: "Zombie Head",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/zombie_head.png",
  ),
  "zombie_horse_spawn_egg": MinecraftMaterial(
    name: "Zombie Horse Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/zombie_horse_spawn_egg.png",
  ),
  "zombie_spawn_egg": MinecraftMaterial(
    name: "Zombie Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/zombie_spawn_egg.png",
  ),
  "zombie_villager_spawn_egg": MinecraftMaterial(
    name: "Zombie Villager Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/zombie_villager_spawn_egg.png",
  ),
  "zombified_piglin_spawn_egg": MinecraftMaterial(
    name: "Zombified Piglin Spawn Egg",
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/zombified_piglin_spawn_egg.png",
  ),
};

const Map<String, String> materialSinceVersion = {
  "black_bundle": "1.21.2",
  "black_harness": "1.21.6",
  "blue_bundle": "1.21.2",
  "blue_harness": "1.21.6",
  "brown_bundle": "1.21.2",
  "brown_harness": "1.21.6",
  "bundle": "1.21.2",
  "bush": "1.21.5",
  "cactus_flower": "1.21.5",
  "chiseled_resin_bricks": "1.21.4",
  "closed_eyeblossom": "1.21.4",
  "copper_bulb": "1.21.9",
  "copper_chain": "1.21.9",
  "copper_door": "1.21.9",
  "copper_grate": "1.21.9",
  "copper_lantern": "1.21.9",
  "copper_pickaxe": "1.21.9",
  "copper_axe": "1.21.9",
  "copper_shovel": "1.21.9",
  "copper_hoe": "1.21.9",
  "copper_sword": "1.21.9",
  "copper_helmet": "1.21.9",
  "copper_chestplate": "1.21.9",
  "copper_leggings": "1.21.9",
  "copper_boots": "1.21.9",
  "copper_horse_armor": "1.21.9",
  "copper_nugget": "1.21.9",
  "copper_golem_spawn_egg": "1.21.9",
  "copper_trapdoor": "1.21.9",
  "creaking_heart": "1.21.4",
  "creaking_spawn_egg": "1.21.4",
  "cyan_bundle": "1.21.2",
  "cyan_harness": "1.21.6",
  "dried_ghast": "1.21.6",
  "exposed_copper_bulb": "1.21.9",
  "exposed_copper_chain": "1.21.9",
  "exposed_copper_door": "1.21.9",
  "exposed_copper_grate": "1.21.9",
  "exposed_copper_lantern": "1.21.9",
  "exposed_copper_trapdoor": "1.21.9",
  "firefly_bush": "1.21.5",
  "gray_bundle": "1.21.2",
  "gray_harness": "1.21.6",
  "green_bundle": "1.21.2",
  "green_harness": "1.21.6",
  "happy_ghast_spawn_egg": "1.21.6",
  "leaf_litter": "1.21.5",
  "light_blue_bundle": "1.21.2",
  "light_blue_harness": "1.21.6",
  "light_gray_bundle": "1.21.2",
  "light_gray_harness": "1.21.6",
  "lime_bundle": "1.21.2",
  "lime_harness": "1.21.6",
  "magenta_bundle": "1.21.2",
  "magenta_harness": "1.21.6",
  "music_disc_lava_chicken": "1.21.6",
  "music_disc_tears": "1.21.6",
  "open_eyeblossom": "1.21.4",
  "orange_bundle": "1.21.2",
  "orange_harness": "1.21.6",
  "oxidized_copper_bulb": "1.21.9",
  "oxidized_copper_chain": "1.21.9",
  "oxidized_copper_door": "1.21.9",
  "oxidized_copper_grate": "1.21.9",
  "oxidized_copper_lantern": "1.21.9",
  "oxidized_copper_trapdoor": "1.21.9",
  "pale_hanging_moss": "1.21.4",
  "pale_moss_block": "1.21.4",
  "pale_moss_carpet": "1.21.4",
  "pale_oak_boat": "1.21.4",
  "pale_oak_button": "1.21.4",
  "pale_oak_chest_boat": "1.21.4",
  "pale_oak_door": "1.21.4",
  "pale_oak_fence": "1.21.4",
  "pale_oak_fence_gate": "1.21.4",
  "pale_oak_hanging_sign": "1.21.4",
  "pale_oak_leaves": "1.21.4",
  "pale_oak_log": "1.21.4",
  "pale_oak_planks": "1.21.4",
  "pale_oak_pressure_plate": "1.21.4",
  "pale_oak_sapling": "1.21.4",
  "pale_oak_sign": "1.21.4",
  "pale_oak_slab": "1.21.4",
  "pale_oak_stairs": "1.21.4",
  "pale_oak_trapdoor": "1.21.4",
  "pale_oak_wood": "1.21.4",
  "pink_bundle": "1.21.2",
  "pink_harness": "1.21.6",
  "purple_bundle": "1.21.2",
  "purple_harness": "1.21.6",
  "red_bundle": "1.21.2",
  "red_harness": "1.21.6",
  "resin_block": "1.21.4",
  "resin_brick": "1.21.4",
  "resin_brick_slab": "1.21.4",
  "resin_brick_stairs": "1.21.4",
  "resin_brick_wall": "1.21.4",
  "resin_bricks": "1.21.4",
  "resin_clump": "1.21.4",
  "short_dry_grass": "1.21.5",
  "short_grass": "1.21.5",
  "tall_dry_grass": "1.21.5",
  "waxed_copper_bulb": "1.21.9",
  "waxed_copper_door": "1.21.9",
  "waxed_copper_grate": "1.21.9",
  "waxed_copper_trapdoor": "1.21.9",
  "waxed_exposed_copper_bulb": "1.21.9",
  "waxed_exposed_copper_lantern": "1.21.9",
  "waxed_exposed_copper_door": "1.21.9",
  "waxed_exposed_copper_grate": "1.21.9",
  "waxed_exposed_copper_trapdoor": "1.21.9",
  "waxed_oxidized_copper_bulb": "1.21.9",
  "waxed_oxidized_copper_lantern": "1.21.9",
  "waxed_oxidized_copper_door": "1.21.9",
  "waxed_oxidized_copper_grate": "1.21.9",
  "waxed_oxidized_copper_trapdoor": "1.21.9",
  "waxed_weathered_copper_bulb": "1.21.9",
  "waxed_weathered_copper_lantern": "1.21.9",
  "waxed_weathered_copper_door": "1.21.9",
  "waxed_weathered_copper_grate": "1.21.9",
  "waxed_weathered_copper_trapdoor": "1.21.9",
  "weathered_copper_bulb": "1.21.9",
  "weathered_copper_door": "1.21.9",
  "weathered_copper_grate": "1.21.9",
  "weathered_copper_trapdoor": "1.21.9",
  "weathered_copper_lantern": "1.21.9",
  "white_bundle": "1.21.2",
  "white_harness": "1.21.6",
  "wildflowers": "1.21.5",
  "yellow_bundle": "1.21.2",
  "yellow_harness": "1.21.6",
};

Map<String, MinecraftMaterial> availableMaterials(McVersion version) =>
    Map.fromEntries(
      materials.entries.where(
        (entry) => isMaterialAvailable(entry.key, version),
      ),
    );

bool isMaterialAvailable(String id, McVersion version) {
  final since = materialSinceVersion[id];
  if (since == null) return true;
  final sinceVersion = McVersion.tryParse(since) ?? McVersion.zero;
  return version.compareTo(sinceVersion) >= 0;
}

@freezed
class MinecraftMaterial with _$MinecraftMaterial {
  const factory MinecraftMaterial({
    required String name,
    required List<MaterialProperty> properties,
    required String icon,
  }) = _MinecraftMaterial;

  factory MinecraftMaterial.fromJson(Map<String, dynamic> json) =>
      _$MinecraftMaterialFromJson(json);
}
