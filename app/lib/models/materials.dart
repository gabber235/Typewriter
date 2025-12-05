import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter/models/mc_version.dart";
import "package:typewriter/utils/icons.dart";

part "materials.freezed.dart";
part "materials.g.dart";

Map<String, MinecraftMaterial> availableMaterials(McVersion version) =>
    Map.fromEntries(
      materials.entries.where(
        (entry) =>
            entry.value.since == null ||
            version.compareTo(entry.value.since!) >= 0,
      ),
    );

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
  "air": MinecraftMaterial(
    name: "Air",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/air.png",
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
  "mangrove_propagule": MinecraftMaterial(
    name: "Mangrove Propagule",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.fuel,
    ],
    icon: "assets/materials/mangrove_propagule.png",
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
  "cut_copper_slab": MinecraftMaterial(
    name: "Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_copper_slab.png",
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
  "weathered_cut_copper_slab": MinecraftMaterial(
    name: "Weathered Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/weathered_cut_copper_slab.png",
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
  "waxed_cut_copper_slab": MinecraftMaterial(
    name: "Waxed Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_cut_copper_slab.png",
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
  "waxed_weathered_cut_copper_slab": MinecraftMaterial(
    name: "Waxed Weathered Cut Copper Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/waxed_weathered_cut_copper_slab.png",
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
  "glass": MinecraftMaterial(
    name: "Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/glass.png",
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
  "cobweb": MinecraftMaterial(
    name: "Cobweb",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/cobweb.png",
  ),
  "grass": MinecraftMaterial(
    name: "Grass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
      MaterialProperty.burnable,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/grass.png",
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
  "seagrass": MinecraftMaterial(
    name: "Seagrass",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/seagrass.png",
  ),
  "sea_pickle": MinecraftMaterial(
    name: "Sea Pickle",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/sea_pickle.png",
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
  "cornflower": MinecraftMaterial(
    name: "Cornflower",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/cornflower.png",
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
  "wither_rose": MinecraftMaterial(
    name: "Wither Rose",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/wither_rose.png",
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
  "brown_mushroom": MinecraftMaterial(
    name: "Brown Mushroom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/brown_mushroom.png",
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
  "crimson_fungus": MinecraftMaterial(
    name: "Crimson Fungus",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/crimson_fungus.png",
  ),
  "warped_fungus": MinecraftMaterial(
    name: "Warped Fungus",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/warped_fungus.png",
  ),
  "crimson_roots": MinecraftMaterial(
    name: "Crimson Roots",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/crimson_roots.png",
  ),
  "warped_roots": MinecraftMaterial(
    name: "Warped Roots",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/warped_roots.png",
  ),
  "nether_sprouts": MinecraftMaterial(
    name: "Nether Sprouts",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/nether_sprouts.png",
  ),
  "weeping_vines": MinecraftMaterial(
    name: "Weeping Vines",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/weeping_vines.png",
  ),
  "twisting_vines": MinecraftMaterial(
    name: "Twisting Vines",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/twisting_vines.png",
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
  "kelp": MinecraftMaterial(
    name: "Kelp",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/kelp.png",
  ),
  "moss_carpet": MinecraftMaterial(
    name: "Moss Carpet",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/moss_carpet.png",
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
  "big_dripleaf": MinecraftMaterial(
    name: "Big Dripleaf",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/big_dripleaf.png",
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
  "crimson_slab": MinecraftMaterial(
    name: "Crimson Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_slab.png",
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
  "stone_slab": MinecraftMaterial(
    name: "Stone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_slab.png",
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
  "sandstone_slab": MinecraftMaterial(
    name: "Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sandstone_slab.png",
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
  "petrified_oak_slab": MinecraftMaterial(
    name: "Petrified Oak Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/petrified_oak_slab.png",
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
  "brick_slab": MinecraftMaterial(
    name: "Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brick_slab.png",
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
  "mud_brick_slab": MinecraftMaterial(
    name: "Mud Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mud_brick_slab.png",
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
  "quartz_slab": MinecraftMaterial(
    name: "Quartz Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/quartz_slab.png",
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
  "cut_red_sandstone_slab": MinecraftMaterial(
    name: "Cut Red Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cut_red_sandstone_slab.png",
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
  "prismarine_slab": MinecraftMaterial(
    name: "Prismarine Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/prismarine_slab.png",
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
  "dark_prismarine_slab": MinecraftMaterial(
    name: "Dark Prismarine Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dark_prismarine_slab.png",
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
  "torch": MinecraftMaterial(
    name: "Torch",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/torch.png",
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
  "chorus_plant": MinecraftMaterial(
    name: "Chorus Plant",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/chorus_plant.png",
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
  "farmland": MinecraftMaterial(
    name: "Farmland",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/farmland.png",
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
  "snow": MinecraftMaterial(
    name: "Snow",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/snow.png",
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
  "cactus": MinecraftMaterial(
    name: "Cactus",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cactus.png",
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
  "soul_torch": MinecraftMaterial(
    name: "Soul Torch",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/soul_torch.png",
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
  "iron_bars": MinecraftMaterial(
    name: "Iron Bars",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/iron_bars.png",
  ),
  "chain": MinecraftMaterial(
    name: "Chain",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/chain.png",
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
  "lily_pad": MinecraftMaterial(
    name: "Lily Pad",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/lily_pad.png",
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
  "sculk_vein": MinecraftMaterial(
    name: "Sculk Vein",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk_vein.png",
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
  "sculk_shrieker": MinecraftMaterial(
    name: "Sculk Shrieker",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk_shrieker.png",
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
  "end_portal_frame": MinecraftMaterial(
    name: "End Portal Frame",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/end_portal_frame.png",
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
  "cobblestone_wall": MinecraftMaterial(
    name: "Cobblestone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobblestone_wall.png",
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
  "brick_wall": MinecraftMaterial(
    name: "Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brick_wall.png",
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
  "red_sandstone_wall": MinecraftMaterial(
    name: "Red Sandstone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_sandstone_wall.png",
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
  "granite_wall": MinecraftMaterial(
    name: "Granite Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/granite_wall.png",
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
  "mud_brick_wall": MinecraftMaterial(
    name: "Mud Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mud_brick_wall.png",
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
  "andesite_wall": MinecraftMaterial(
    name: "Andesite Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/andesite_wall.png",
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
  "sandstone_wall": MinecraftMaterial(
    name: "Sandstone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sandstone_wall.png",
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
  "diorite_wall": MinecraftMaterial(
    name: "Diorite Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/diorite_wall.png",
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
  "polished_blackstone_wall": MinecraftMaterial(
    name: "Polished Blackstone Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_blackstone_wall.png",
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
  "cobbled_deepslate_wall": MinecraftMaterial(
    name: "Cobbled Deepslate Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cobbled_deepslate_wall.png",
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
  "deepslate_brick_wall": MinecraftMaterial(
    name: "Deepslate Brick Wall",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_brick_wall.png",
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
  "light": MinecraftMaterial(
    name: "Light",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/light.png",
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
  "dirt_path": MinecraftMaterial(
    name: "Dirt Path",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dirt_path.png",
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
  "white_stained_glass": MinecraftMaterial(
    name: "White Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_stained_glass.png",
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
  "magenta_stained_glass": MinecraftMaterial(
    name: "Magenta Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_stained_glass.png",
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
  "yellow_stained_glass": MinecraftMaterial(
    name: "Yellow Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_stained_glass.png",
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
  "pink_stained_glass": MinecraftMaterial(
    name: "Pink Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_stained_glass.png",
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
  "light_gray_stained_glass": MinecraftMaterial(
    name: "Light Gray Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_stained_glass.png",
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
  "purple_stained_glass": MinecraftMaterial(
    name: "Purple Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_stained_glass.png",
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
  "brown_stained_glass": MinecraftMaterial(
    name: "Brown Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_stained_glass.png",
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
  "red_stained_glass": MinecraftMaterial(
    name: "Red Stained Glass",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_stained_glass.png",
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
  "white_stained_glass_pane": MinecraftMaterial(
    name: "White Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_stained_glass_pane.png",
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
  "magenta_stained_glass_pane": MinecraftMaterial(
    name: "Magenta Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_stained_glass_pane.png",
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
  "yellow_stained_glass_pane": MinecraftMaterial(
    name: "Yellow Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_stained_glass_pane.png",
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
  "pink_stained_glass_pane": MinecraftMaterial(
    name: "Pink Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_stained_glass_pane.png",
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
  "light_gray_stained_glass_pane": MinecraftMaterial(
    name: "Light Gray Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_stained_glass_pane.png",
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
  "purple_stained_glass_pane": MinecraftMaterial(
    name: "Purple Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_stained_glass_pane.png",
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
  "brown_stained_glass_pane": MinecraftMaterial(
    name: "Brown Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_stained_glass_pane.png",
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
  "red_stained_glass_pane": MinecraftMaterial(
    name: "Red Stained Glass Pane",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_stained_glass_pane.png",
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
  "sea_lantern": MinecraftMaterial(
    name: "Sea Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sea_lantern.png",
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
  "structure_void": MinecraftMaterial(
    name: "Structure Void",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/structure_void.png",
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
  "turtle_egg": MinecraftMaterial(
    name: "Turtle Egg",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/turtle_egg.png",
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
  "tube_coral": MinecraftMaterial(
    name: "Tube Coral",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/tube_coral.png",
  ),
  "brain_coral": MinecraftMaterial(
    name: "Brain Coral",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/brain_coral.png",
  ),
  "bubble_coral": MinecraftMaterial(
    name: "Bubble Coral",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/bubble_coral.png",
  ),
  "fire_coral": MinecraftMaterial(
    name: "Fire Coral",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/fire_coral.png",
  ),
  "horn_coral": MinecraftMaterial(
    name: "Horn Coral",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/horn_coral.png",
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
  "dead_bubble_coral": MinecraftMaterial(
    name: "Dead Bubble Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_bubble_coral.png",
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
  "dead_horn_coral": MinecraftMaterial(
    name: "Dead Horn Coral",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_horn_coral.png",
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
  "tube_coral_fan": MinecraftMaterial(
    name: "Tube Coral Fan",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/tube_coral_fan.png",
  ),
  "brain_coral_fan": MinecraftMaterial(
    name: "Brain Coral Fan",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/brain_coral_fan.png",
  ),
  "bubble_coral_fan": MinecraftMaterial(
    name: "Bubble Coral Fan",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/bubble_coral_fan.png",
  ),
  "fire_coral_fan": MinecraftMaterial(
    name: "Fire Coral Fan",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/fire_coral_fan.png",
  ),
  "horn_coral_fan": MinecraftMaterial(
    name: "Horn Coral Fan",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/horn_coral_fan.png",
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
  "dead_brain_coral_fan": MinecraftMaterial(
    name: "Dead Brain Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_brain_coral_fan.png",
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
  "dead_fire_coral_fan": MinecraftMaterial(
    name: "Dead Fire Coral Fan",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/dead_fire_coral_fan.png",
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
  "conduit": MinecraftMaterial(
    name: "Conduit",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/conduit.png",
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
  "polished_granite_slab": MinecraftMaterial(
    name: "Polished Granite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_granite_slab.png",
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
  "mossy_stone_brick_slab": MinecraftMaterial(
    name: "Mossy Stone Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_stone_brick_slab.png",
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
  "mossy_cobblestone_slab": MinecraftMaterial(
    name: "Mossy Cobblestone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/mossy_cobblestone_slab.png",
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
  "smooth_sandstone_slab": MinecraftMaterial(
    name: "Smooth Sandstone Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/smooth_sandstone_slab.png",
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
  "granite_slab": MinecraftMaterial(
    name: "Granite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/granite_slab.png",
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
  "red_nether_brick_slab": MinecraftMaterial(
    name: "Red Nether Brick Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_nether_brick_slab.png",
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
  "diorite_slab": MinecraftMaterial(
    name: "Diorite Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/diorite_slab.png",
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
  "polished_deepslate_slab": MinecraftMaterial(
    name: "Polished Deepslate Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/polished_deepslate_slab.png",
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
  "deepslate_tile_slab": MinecraftMaterial(
    name: "Deepslate Tile Slab",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/deepslate_tile_slab.png",
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
  "redstone": MinecraftMaterial(
    name: "Redstone",
    properties: [MaterialProperty.item],
    icon: "assets/materials/redstone.png",
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
  "redstone_block": MinecraftMaterial(
    name: "Redstone Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/redstone_block.png",
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
  "piston": MinecraftMaterial(
    name: "Piston",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/piston.png",
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
  "honey_block": MinecraftMaterial(
    name: "Honey Block",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/honey_block.png",
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
  "lightning_rod": MinecraftMaterial(
    name: "Lightning Rod",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lightning_rod.png",
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
  "sculk_sensor": MinecraftMaterial(
    name: "Sculk Sensor",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/sculk_sensor.png",
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
  "polished_blackstone_button": MinecraftMaterial(
    name: "Polished Blackstone Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/polished_blackstone_button.png",
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
  "crimson_button": MinecraftMaterial(
    name: "Crimson Button",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/crimson_button.png",
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
  "stone_pressure_plate": MinecraftMaterial(
    name: "Stone Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/stone_pressure_plate.png",
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
  "light_weighted_pressure_plate": MinecraftMaterial(
    name: "Light Weighted Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_weighted_pressure_plate.png",
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
  "crimson_pressure_plate": MinecraftMaterial(
    name: "Crimson Pressure Plate",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_pressure_plate.png",
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
  "powered_rail": MinecraftMaterial(
    name: "Powered Rail",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/powered_rail.png",
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
  "rail": MinecraftMaterial(
    name: "Rail",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/rail.png",
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
  "saddle": MinecraftMaterial(
    name: "Saddle",
    properties: [MaterialProperty.item],
    icon: "assets/materials/saddle.png",
  ),
  "minecart": MinecraftMaterial(
    name: "Minecart",
    properties: [MaterialProperty.item],
    icon: "assets/materials/minecart.png",
  ),
  "chest_minecart": MinecraftMaterial(
    name: "Chest Minecart",
    properties: [MaterialProperty.item],
    icon: "assets/materials/chest_minecart.png",
  ),
  "furnace_minecart": MinecraftMaterial(
    name: "Furnace Minecart",
    properties: [MaterialProperty.item],
    icon: "assets/materials/furnace_minecart.png",
  ),
  "tnt_minecart": MinecraftMaterial(
    name: "Tnt Minecart",
    properties: [MaterialProperty.item],
    icon: "assets/materials/tnt_minecart.png",
  ),
  "hopper_minecart": MinecraftMaterial(
    name: "Hopper Minecart",
    properties: [MaterialProperty.item],
    icon: "assets/materials/hopper_minecart.png",
  ),
  "carrot_on_a_stick": MinecraftMaterial(
    name: "Carrot On A Stick",
    properties: [MaterialProperty.item],
    icon: "assets/materials/carrot_on_a_stick.png",
  ),
  "warped_fungus_on_a_stick": MinecraftMaterial(
    name: "Warped Fungus On A Stick",
    properties: [MaterialProperty.item],
    icon: "assets/materials/warped_fungus_on_a_stick.png",
  ),
  "elytra": MinecraftMaterial(
    name: "Elytra",
    properties: [MaterialProperty.item],
    icon: "assets/materials/elytra.png",
  ),
  "oak_boat": MinecraftMaterial(
    name: "Oak Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/oak_boat.png",
  ),
  "oak_chest_boat": MinecraftMaterial(
    name: "Oak Chest Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/oak_chest_boat.png",
  ),
  "spruce_boat": MinecraftMaterial(
    name: "Spruce Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/spruce_boat.png",
  ),
  "spruce_chest_boat": MinecraftMaterial(
    name: "Spruce Chest Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/spruce_chest_boat.png",
  ),
  "birch_boat": MinecraftMaterial(
    name: "Birch Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/birch_boat.png",
  ),
  "birch_chest_boat": MinecraftMaterial(
    name: "Birch Chest Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/birch_chest_boat.png",
  ),
  "jungle_boat": MinecraftMaterial(
    name: "Jungle Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/jungle_boat.png",
  ),
  "jungle_chest_boat": MinecraftMaterial(
    name: "Jungle Chest Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/jungle_chest_boat.png",
  ),
  "acacia_boat": MinecraftMaterial(
    name: "Acacia Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/acacia_boat.png",
  ),
  "acacia_chest_boat": MinecraftMaterial(
    name: "Acacia Chest Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/acacia_chest_boat.png",
  ),
  "dark_oak_boat": MinecraftMaterial(
    name: "Dark Oak Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/dark_oak_boat.png",
  ),
  "dark_oak_chest_boat": MinecraftMaterial(
    name: "Dark Oak Chest Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/dark_oak_chest_boat.png",
  ),
  "mangrove_boat": MinecraftMaterial(
    name: "Mangrove Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/mangrove_boat.png",
  ),
  "mangrove_chest_boat": MinecraftMaterial(
    name: "Mangrove Chest Boat",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/mangrove_chest_boat.png",
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
  "turtle_helmet": MinecraftMaterial(
    name: "Turtle Helmet",
    properties: [MaterialProperty.item],
    icon: "assets/materials/turtle_helmet.png",
  ),
  "scute": MinecraftMaterial(
    name: "Scute",
    properties: [MaterialProperty.item],
    icon: "assets/materials/scute.png",
  ),
  "flint_and_steel": MinecraftMaterial(
    name: "Flint And Steel",
    properties: [MaterialProperty.item],
    icon: "assets/materials/flint_and_steel.png",
  ),
  "apple": MinecraftMaterial(
    name: "Apple",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/apple.png",
  ),
  "bow": MinecraftMaterial(
    name: "Bow",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/bow.png",
  ),
  "arrow": MinecraftMaterial(
    name: "Arrow",
    properties: [MaterialProperty.item],
    icon: "assets/materials/arrow.png",
  ),
  "coal": MinecraftMaterial(
    name: "Coal",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/coal.png",
  ),
  "charcoal": MinecraftMaterial(
    name: "Charcoal",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/charcoal.png",
  ),
  "diamond": MinecraftMaterial(
    name: "Diamond",
    properties: [MaterialProperty.item],
    icon: "assets/materials/diamond.png",
  ),
  "emerald": MinecraftMaterial(
    name: "Emerald",
    properties: [MaterialProperty.item],
    icon: "assets/materials/emerald.png",
  ),
  "lapis_lazuli": MinecraftMaterial(
    name: "Lapis Lazuli",
    properties: [MaterialProperty.item],
    icon: "assets/materials/lapis_lazuli.png",
  ),
  "quartz": MinecraftMaterial(
    name: "Quartz",
    properties: [MaterialProperty.item],
    icon: "assets/materials/quartz.png",
  ),
  "amethyst_shard": MinecraftMaterial(
    name: "Amethyst Shard",
    properties: [MaterialProperty.item],
    icon: "assets/materials/amethyst_shard.png",
  ),
  "raw_iron": MinecraftMaterial(
    name: "Raw Iron",
    properties: [MaterialProperty.item],
    icon: "assets/materials/raw_iron.png",
  ),
  "iron_ingot": MinecraftMaterial(
    name: "Iron Ingot",
    properties: [MaterialProperty.item],
    icon: "assets/materials/iron_ingot.png",
  ),
  "raw_copper": MinecraftMaterial(
    name: "Raw Copper",
    properties: [MaterialProperty.item],
    icon: "assets/materials/raw_copper.png",
  ),
  "copper_ingot": MinecraftMaterial(
    name: "Copper Ingot",
    properties: [MaterialProperty.item],
    icon: "assets/materials/copper_ingot.png",
  ),
  "raw_gold": MinecraftMaterial(
    name: "Raw Gold",
    properties: [MaterialProperty.item],
    icon: "assets/materials/raw_gold.png",
  ),
  "gold_ingot": MinecraftMaterial(
    name: "Gold Ingot",
    properties: [MaterialProperty.item],
    icon: "assets/materials/gold_ingot.png",
  ),
  "netherite_ingot": MinecraftMaterial(
    name: "Netherite Ingot",
    properties: [MaterialProperty.item],
    icon: "assets/materials/netherite_ingot.png",
  ),
  "netherite_scrap": MinecraftMaterial(
    name: "Netherite Scrap",
    properties: [MaterialProperty.item],
    icon: "assets/materials/netherite_scrap.png",
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
  "wooden_shovel": MinecraftMaterial(
    name: "Wooden Shovel",
    properties: [
      MaterialProperty.item,
      MaterialProperty.fuel,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/wooden_shovel.png",
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
  "stone_sword": MinecraftMaterial(
    name: "Stone Sword",
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/stone_sword.png",
  ),
  "stone_shovel": MinecraftMaterial(
    name: "Stone Shovel",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/stone_shovel.png",
  ),
  "stone_pickaxe": MinecraftMaterial(
    name: "Stone Pickaxe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/stone_pickaxe.png",
  ),
  "stone_axe": MinecraftMaterial(
    name: "Stone Axe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/stone_axe.png",
  ),
  "stone_hoe": MinecraftMaterial(
    name: "Stone Hoe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/stone_hoe.png",
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
  "golden_shovel": MinecraftMaterial(
    name: "Golden Shovel",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/golden_shovel.png",
  ),
  "golden_pickaxe": MinecraftMaterial(
    name: "Golden Pickaxe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/golden_pickaxe.png",
  ),
  "golden_axe": MinecraftMaterial(
    name: "Golden Axe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/golden_axe.png",
  ),
  "golden_hoe": MinecraftMaterial(
    name: "Golden Hoe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/golden_hoe.png",
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
  "iron_shovel": MinecraftMaterial(
    name: "Iron Shovel",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/iron_shovel.png",
  ),
  "iron_pickaxe": MinecraftMaterial(
    name: "Iron Pickaxe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/iron_pickaxe.png",
  ),
  "iron_axe": MinecraftMaterial(
    name: "Iron Axe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/iron_axe.png",
  ),
  "iron_hoe": MinecraftMaterial(
    name: "Iron Hoe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/iron_hoe.png",
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
  "diamond_shovel": MinecraftMaterial(
    name: "Diamond Shovel",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/diamond_shovel.png",
  ),
  "diamond_pickaxe": MinecraftMaterial(
    name: "Diamond Pickaxe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/diamond_pickaxe.png",
  ),
  "diamond_axe": MinecraftMaterial(
    name: "Diamond Axe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/diamond_axe.png",
  ),
  "diamond_hoe": MinecraftMaterial(
    name: "Diamond Hoe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/diamond_hoe.png",
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
  "netherite_shovel": MinecraftMaterial(
    name: "Netherite Shovel",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/netherite_shovel.png",
  ),
  "netherite_pickaxe": MinecraftMaterial(
    name: "Netherite Pickaxe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/netherite_pickaxe.png",
  ),
  "netherite_axe": MinecraftMaterial(
    name: "Netherite Axe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/netherite_axe.png",
  ),
  "netherite_hoe": MinecraftMaterial(
    name: "Netherite Hoe",
    properties: [MaterialProperty.item, MaterialProperty.tool],
    icon: "assets/materials/netherite_hoe.png",
  ),
  "stick": MinecraftMaterial(
    name: "Stick",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/stick.png",
  ),
  "bowl": MinecraftMaterial(
    name: "Bowl",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/bowl.png",
  ),
  "mushroom_stew": MinecraftMaterial(
    name: "Mushroom Stew",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/mushroom_stew.png",
  ),
  "string": MinecraftMaterial(
    name: "String",
    properties: [MaterialProperty.item],
    icon: "assets/materials/string.png",
  ),
  "feather": MinecraftMaterial(
    name: "Feather",
    properties: [MaterialProperty.item],
    icon: "assets/materials/feather.png",
  ),
  "gunpowder": MinecraftMaterial(
    name: "Gunpowder",
    properties: [MaterialProperty.item],
    icon: "assets/materials/gunpowder.png",
  ),
  "wheat_seeds": MinecraftMaterial(
    name: "Wheat Seeds",
    properties: [MaterialProperty.item],
    icon: "assets/materials/wheat_seeds.png",
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
  "bread": MinecraftMaterial(
    name: "Bread",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/bread.png",
  ),
  "leather_helmet": MinecraftMaterial(
    name: "Leather Helmet",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/leather_helmet.png",
  ),
  "leather_chestplate": MinecraftMaterial(
    name: "Leather Chestplate",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/leather_chestplate.png",
  ),
  "leather_leggings": MinecraftMaterial(
    name: "Leather Leggings",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/leather_leggings.png",
  ),
  "leather_boots": MinecraftMaterial(
    name: "Leather Boots",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/leather_boots.png",
  ),
  "chainmail_helmet": MinecraftMaterial(
    name: "Chainmail Helmet",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/chainmail_helmet.png",
  ),
  "chainmail_chestplate": MinecraftMaterial(
    name: "Chainmail Chestplate",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/chainmail_chestplate.png",
  ),
  "chainmail_leggings": MinecraftMaterial(
    name: "Chainmail Leggings",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/chainmail_leggings.png",
  ),
  "chainmail_boots": MinecraftMaterial(
    name: "Chainmail Boots",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/chainmail_boots.png",
  ),
  "iron_helmet": MinecraftMaterial(
    name: "Iron Helmet",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/iron_helmet.png",
  ),
  "iron_chestplate": MinecraftMaterial(
    name: "Iron Chestplate",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/iron_chestplate.png",
  ),
  "iron_leggings": MinecraftMaterial(
    name: "Iron Leggings",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/iron_leggings.png",
  ),
  "iron_boots": MinecraftMaterial(
    name: "Iron Boots",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/iron_boots.png",
  ),
  "diamond_helmet": MinecraftMaterial(
    name: "Diamond Helmet",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/diamond_helmet.png",
  ),
  "diamond_chestplate": MinecraftMaterial(
    name: "Diamond Chestplate",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/diamond_chestplate.png",
  ),
  "diamond_leggings": MinecraftMaterial(
    name: "Diamond Leggings",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/diamond_leggings.png",
  ),
  "diamond_boots": MinecraftMaterial(
    name: "Diamond Boots",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/diamond_boots.png",
  ),
  "golden_helmet": MinecraftMaterial(
    name: "Golden Helmet",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/golden_helmet.png",
  ),
  "golden_chestplate": MinecraftMaterial(
    name: "Golden Chestplate",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/golden_chestplate.png",
  ),
  "golden_leggings": MinecraftMaterial(
    name: "Golden Leggings",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/golden_leggings.png",
  ),
  "golden_boots": MinecraftMaterial(
    name: "Golden Boots",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/golden_boots.png",
  ),
  "netherite_helmet": MinecraftMaterial(
    name: "Netherite Helmet",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/netherite_helmet.png",
  ),
  "netherite_chestplate": MinecraftMaterial(
    name: "Netherite Chestplate",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/netherite_chestplate.png",
  ),
  "netherite_leggings": MinecraftMaterial(
    name: "Netherite Leggings",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/netherite_leggings.png",
  ),
  "netherite_boots": MinecraftMaterial(
    name: "Netherite Boots",
    properties: [MaterialProperty.item, MaterialProperty.armor],
    icon: "assets/materials/netherite_boots.png",
  ),
  "flint": MinecraftMaterial(
    name: "Flint",
    properties: [MaterialProperty.item],
    icon: "assets/materials/flint.png",
  ),
  "porkchop": MinecraftMaterial(
    name: "Porkchop",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/porkchop.png",
  ),
  "cooked_porkchop": MinecraftMaterial(
    name: "Cooked Porkchop",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cooked_porkchop.png",
  ),
  "painting": MinecraftMaterial(
    name: "Painting",
    properties: [MaterialProperty.item],
    icon: "assets/materials/painting.png",
  ),
  "golden_apple": MinecraftMaterial(
    name: "Golden Apple",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/golden_apple.png",
  ),
  "enchanted_golden_apple": MinecraftMaterial(
    name: "Enchanted Golden Apple",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/enchanted_golden_apple.png",
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
  "bucket": MinecraftMaterial(
    name: "Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/bucket.png",
  ),
  "water_bucket": MinecraftMaterial(
    name: "Water Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/water_bucket.png",
  ),
  "lava_bucket": MinecraftMaterial(
    name: "Lava Bucket",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/lava_bucket.png",
  ),
  "powder_snow_bucket": MinecraftMaterial(
    name: "Powder Snow Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/powder_snow_bucket.png",
  ),
  "snowball": MinecraftMaterial(
    name: "Snowball",
    properties: [MaterialProperty.item],
    icon: "assets/materials/snowball.png",
  ),
  "leather": MinecraftMaterial(
    name: "Leather",
    properties: [MaterialProperty.item],
    icon: "assets/materials/leather.png",
  ),
  "milk_bucket": MinecraftMaterial(
    name: "Milk Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/milk_bucket.png",
  ),
  "pufferfish_bucket": MinecraftMaterial(
    name: "Pufferfish Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/pufferfish_bucket.png",
  ),
  "salmon_bucket": MinecraftMaterial(
    name: "Salmon Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/salmon_bucket.png",
  ),
  "cod_bucket": MinecraftMaterial(
    name: "Cod Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/cod_bucket.png",
  ),
  "tropical_fish_bucket": MinecraftMaterial(
    name: "Tropical Fish Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/tropical_fish_bucket.png",
  ),
  "axolotl_bucket": MinecraftMaterial(
    name: "Axolotl Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/axolotl_bucket.png",
  ),
  "tadpole_bucket": MinecraftMaterial(
    name: "Tadpole Bucket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/tadpole_bucket.png",
  ),
  "brick": MinecraftMaterial(
    name: "Brick",
    properties: [MaterialProperty.item],
    icon: "assets/materials/brick.png",
  ),
  "clay_ball": MinecraftMaterial(
    name: "Clay Ball",
    properties: [MaterialProperty.item],
    icon: "assets/materials/clay_ball.png",
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
  "paper": MinecraftMaterial(
    name: "Paper",
    properties: [MaterialProperty.item],
    icon: "assets/materials/paper.png",
  ),
  "book": MinecraftMaterial(
    name: "Book",
    properties: [MaterialProperty.item],
    icon: "assets/materials/book.png",
  ),
  "slime_ball": MinecraftMaterial(
    name: "Slime Ball",
    properties: [MaterialProperty.item],
    icon: "assets/materials/slime_ball.png",
  ),
  "egg": MinecraftMaterial(
    name: "Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/egg.png",
  ),
  "compass": MinecraftMaterial(
    name: "Compass",
    properties: [MaterialProperty.item],
    icon: "assets/materials/compass.png",
  ),
  "recovery_compass": MinecraftMaterial(
    name: "Recovery Compass",
    properties: [MaterialProperty.item],
    icon: "assets/materials/recovery_compass.png",
  ),
  "fishing_rod": MinecraftMaterial(
    name: "Fishing Rod",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/fishing_rod.png",
  ),
  "clock": MinecraftMaterial(
    name: "Clock",
    properties: [MaterialProperty.item],
    icon: "assets/materials/clock.png",
  ),
  "spyglass": MinecraftMaterial(
    name: "Spyglass",
    properties: [MaterialProperty.item],
    icon: "assets/materials/spyglass.png",
  ),
  "glowstone_dust": MinecraftMaterial(
    name: "Glowstone Dust",
    properties: [MaterialProperty.item],
    icon: "assets/materials/glowstone_dust.png",
  ),
  "cod": MinecraftMaterial(
    name: "Cod",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cod.png",
  ),
  "salmon": MinecraftMaterial(
    name: "Salmon",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/salmon.png",
  ),
  "tropical_fish": MinecraftMaterial(
    name: "Tropical Fish",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/tropical_fish.png",
  ),
  "pufferfish": MinecraftMaterial(
    name: "Pufferfish",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/pufferfish.png",
  ),
  "cooked_cod": MinecraftMaterial(
    name: "Cooked Cod",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cooked_cod.png",
  ),
  "cooked_salmon": MinecraftMaterial(
    name: "Cooked Salmon",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cooked_salmon.png",
  ),
  "ink_sac": MinecraftMaterial(
    name: "Ink Sac",
    properties: [MaterialProperty.item],
    icon: "assets/materials/ink_sac.png",
  ),
  "glow_ink_sac": MinecraftMaterial(
    name: "Glow Ink Sac",
    properties: [MaterialProperty.item],
    icon: "assets/materials/glow_ink_sac.png",
  ),
  "cocoa_beans": MinecraftMaterial(
    name: "Cocoa Beans",
    properties: [MaterialProperty.item],
    icon: "assets/materials/cocoa_beans.png",
  ),
  "white_dye": MinecraftMaterial(
    name: "White Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/white_dye.png",
  ),
  "orange_dye": MinecraftMaterial(
    name: "Orange Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/orange_dye.png",
  ),
  "magenta_dye": MinecraftMaterial(
    name: "Magenta Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/magenta_dye.png",
  ),
  "light_blue_dye": MinecraftMaterial(
    name: "Light Blue Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/light_blue_dye.png",
  ),
  "yellow_dye": MinecraftMaterial(
    name: "Yellow Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/yellow_dye.png",
  ),
  "lime_dye": MinecraftMaterial(
    name: "Lime Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/lime_dye.png",
  ),
  "pink_dye": MinecraftMaterial(
    name: "Pink Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/pink_dye.png",
  ),
  "gray_dye": MinecraftMaterial(
    name: "Gray Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/gray_dye.png",
  ),
  "light_gray_dye": MinecraftMaterial(
    name: "Light Gray Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/light_gray_dye.png",
  ),
  "cyan_dye": MinecraftMaterial(
    name: "Cyan Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/cyan_dye.png",
  ),
  "purple_dye": MinecraftMaterial(
    name: "Purple Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/purple_dye.png",
  ),
  "blue_dye": MinecraftMaterial(
    name: "Blue Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/blue_dye.png",
  ),
  "brown_dye": MinecraftMaterial(
    name: "Brown Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/brown_dye.png",
  ),
  "green_dye": MinecraftMaterial(
    name: "Green Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/green_dye.png",
  ),
  "red_dye": MinecraftMaterial(
    name: "Red Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/red_dye.png",
  ),
  "black_dye": MinecraftMaterial(
    name: "Black Dye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/black_dye.png",
  ),
  "bone_meal": MinecraftMaterial(
    name: "Bone Meal",
    properties: [MaterialProperty.item],
    icon: "assets/materials/bone_meal.png",
  ),
  "bone": MinecraftMaterial(
    name: "Bone",
    properties: [MaterialProperty.item],
    icon: "assets/materials/bone.png",
  ),
  "sugar": MinecraftMaterial(
    name: "Sugar",
    properties: [MaterialProperty.item],
    icon: "assets/materials/sugar.png",
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
  "cookie": MinecraftMaterial(
    name: "Cookie",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cookie.png",
  ),
  "filled_map": MinecraftMaterial(
    name: "Filled Map",
    properties: [MaterialProperty.item],
    icon: "assets/materials/filled_map.png",
  ),
  "shears": MinecraftMaterial(
    name: "Shears",
    properties: [MaterialProperty.item],
    icon: "assets/materials/shears.png",
  ),
  "melon_slice": MinecraftMaterial(
    name: "Melon Slice",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/melon_slice.png",
  ),
  "dried_kelp": MinecraftMaterial(
    name: "Dried Kelp",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/dried_kelp.png",
  ),
  "pumpkin_seeds": MinecraftMaterial(
    name: "Pumpkin Seeds",
    properties: [MaterialProperty.item],
    icon: "assets/materials/pumpkin_seeds.png",
  ),
  "melon_seeds": MinecraftMaterial(
    name: "Melon Seeds",
    properties: [MaterialProperty.item],
    icon: "assets/materials/melon_seeds.png",
  ),
  "beef": MinecraftMaterial(
    name: "Beef",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/beef.png",
  ),
  "cooked_beef": MinecraftMaterial(
    name: "Cooked Beef",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cooked_beef.png",
  ),
  "chicken": MinecraftMaterial(
    name: "Chicken",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/chicken.png",
  ),
  "cooked_chicken": MinecraftMaterial(
    name: "Cooked Chicken",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cooked_chicken.png",
  ),
  "rotten_flesh": MinecraftMaterial(
    name: "Rotten Flesh",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/rotten_flesh.png",
  ),
  "ender_pearl": MinecraftMaterial(
    name: "Ender Pearl",
    properties: [MaterialProperty.item],
    icon: "assets/materials/ender_pearl.png",
  ),
  "blaze_rod": MinecraftMaterial(
    name: "Blaze Rod",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/blaze_rod.png",
  ),
  "ghast_tear": MinecraftMaterial(
    name: "Ghast Tear",
    properties: [MaterialProperty.item],
    icon: "assets/materials/ghast_tear.png",
  ),
  "gold_nugget": MinecraftMaterial(
    name: "Gold Nugget",
    properties: [MaterialProperty.item],
    icon: "assets/materials/gold_nugget.png",
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
  "potion": MinecraftMaterial(
    name: "Potion",
    properties: [MaterialProperty.item],
    icon: "assets/materials/potion.png",
  ),
  "glass_bottle": MinecraftMaterial(
    name: "Glass Bottle",
    properties: [MaterialProperty.item],
    icon: "assets/materials/glass_bottle.png",
  ),
  "spider_eye": MinecraftMaterial(
    name: "Spider Eye",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/spider_eye.png",
  ),
  "fermented_spider_eye": MinecraftMaterial(
    name: "Fermented Spider Eye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/fermented_spider_eye.png",
  ),
  "blaze_powder": MinecraftMaterial(
    name: "Blaze Powder",
    properties: [MaterialProperty.item],
    icon: "assets/materials/blaze_powder.png",
  ),
  "magma_cream": MinecraftMaterial(
    name: "Magma Cream",
    properties: [MaterialProperty.item],
    icon: "assets/materials/magma_cream.png",
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
  "ender_eye": MinecraftMaterial(
    name: "Ender Eye",
    properties: [MaterialProperty.item],
    icon: "assets/materials/ender_eye.png",
  ),
  "glistering_melon_slice": MinecraftMaterial(
    name: "Glistering Melon Slice",
    properties: [MaterialProperty.item],
    icon: "assets/materials/glistering_melon_slice.png",
  ),
  "allay_spawn_egg": MinecraftMaterial(
    name: "Allay Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/allay_spawn_egg.png",
  ),
  "axolotl_spawn_egg": MinecraftMaterial(
    name: "Axolotl Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/axolotl_spawn_egg.png",
  ),
  "bat_spawn_egg": MinecraftMaterial(
    name: "Bat Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/bat_spawn_egg.png",
  ),
  "bee_spawn_egg": MinecraftMaterial(
    name: "Bee Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/bee_spawn_egg.png",
  ),
  "blaze_spawn_egg": MinecraftMaterial(
    name: "Blaze Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/blaze_spawn_egg.png",
  ),
  "cat_spawn_egg": MinecraftMaterial(
    name: "Cat Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/cat_spawn_egg.png",
  ),
  "cave_spider_spawn_egg": MinecraftMaterial(
    name: "Cave Spider Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/cave_spider_spawn_egg.png",
  ),
  "chicken_spawn_egg": MinecraftMaterial(
    name: "Chicken Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/chicken_spawn_egg.png",
  ),
  "cod_spawn_egg": MinecraftMaterial(
    name: "Cod Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/cod_spawn_egg.png",
  ),
  "cow_spawn_egg": MinecraftMaterial(
    name: "Cow Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/cow_spawn_egg.png",
  ),
  "creeper_spawn_egg": MinecraftMaterial(
    name: "Creeper Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/creeper_spawn_egg.png",
  ),
  "dolphin_spawn_egg": MinecraftMaterial(
    name: "Dolphin Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/dolphin_spawn_egg.png",
  ),
  "donkey_spawn_egg": MinecraftMaterial(
    name: "Donkey Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/donkey_spawn_egg.png",
  ),
  "drowned_spawn_egg": MinecraftMaterial(
    name: "Drowned Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/drowned_spawn_egg.png",
  ),
  "elder_guardian_spawn_egg": MinecraftMaterial(
    name: "Elder Guardian Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/elder_guardian_spawn_egg.png",
  ),
  "enderman_spawn_egg": MinecraftMaterial(
    name: "Enderman Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/enderman_spawn_egg.png",
  ),
  "endermite_spawn_egg": MinecraftMaterial(
    name: "Endermite Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/endermite_spawn_egg.png",
  ),
  "evoker_spawn_egg": MinecraftMaterial(
    name: "Evoker Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/evoker_spawn_egg.png",
  ),
  "fox_spawn_egg": MinecraftMaterial(
    name: "Fox Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/fox_spawn_egg.png",
  ),
  "frog_spawn_egg": MinecraftMaterial(
    name: "Frog Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/frog_spawn_egg.png",
  ),
  "ghast_spawn_egg": MinecraftMaterial(
    name: "Ghast Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/ghast_spawn_egg.png",
  ),
  "glow_squid_spawn_egg": MinecraftMaterial(
    name: "Glow Squid Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/glow_squid_spawn_egg.png",
  ),
  "goat_spawn_egg": MinecraftMaterial(
    name: "Goat Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/goat_spawn_egg.png",
  ),
  "guardian_spawn_egg": MinecraftMaterial(
    name: "Guardian Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/guardian_spawn_egg.png",
  ),
  "hoglin_spawn_egg": MinecraftMaterial(
    name: "Hoglin Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/hoglin_spawn_egg.png",
  ),
  "horse_spawn_egg": MinecraftMaterial(
    name: "Horse Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/horse_spawn_egg.png",
  ),
  "husk_spawn_egg": MinecraftMaterial(
    name: "Husk Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/husk_spawn_egg.png",
  ),
  "llama_spawn_egg": MinecraftMaterial(
    name: "Llama Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/llama_spawn_egg.png",
  ),
  "magma_cube_spawn_egg": MinecraftMaterial(
    name: "Magma Cube Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/magma_cube_spawn_egg.png",
  ),
  "mooshroom_spawn_egg": MinecraftMaterial(
    name: "Mooshroom Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/mooshroom_spawn_egg.png",
  ),
  "mule_spawn_egg": MinecraftMaterial(
    name: "Mule Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/mule_spawn_egg.png",
  ),
  "ocelot_spawn_egg": MinecraftMaterial(
    name: "Ocelot Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/ocelot_spawn_egg.png",
  ),
  "panda_spawn_egg": MinecraftMaterial(
    name: "Panda Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/panda_spawn_egg.png",
  ),
  "parrot_spawn_egg": MinecraftMaterial(
    name: "Parrot Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/parrot_spawn_egg.png",
  ),
  "phantom_spawn_egg": MinecraftMaterial(
    name: "Phantom Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/phantom_spawn_egg.png",
  ),
  "pig_spawn_egg": MinecraftMaterial(
    name: "Pig Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/pig_spawn_egg.png",
  ),
  "piglin_spawn_egg": MinecraftMaterial(
    name: "Piglin Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/piglin_spawn_egg.png",
  ),
  "piglin_brute_spawn_egg": MinecraftMaterial(
    name: "Piglin Brute Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/piglin_brute_spawn_egg.png",
  ),
  "pillager_spawn_egg": MinecraftMaterial(
    name: "Pillager Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/pillager_spawn_egg.png",
  ),
  "polar_bear_spawn_egg": MinecraftMaterial(
    name: "Polar Bear Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/polar_bear_spawn_egg.png",
  ),
  "pufferfish_spawn_egg": MinecraftMaterial(
    name: "Pufferfish Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/pufferfish_spawn_egg.png",
  ),
  "rabbit_spawn_egg": MinecraftMaterial(
    name: "Rabbit Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/rabbit_spawn_egg.png",
  ),
  "ravager_spawn_egg": MinecraftMaterial(
    name: "Ravager Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/ravager_spawn_egg.png",
  ),
  "salmon_spawn_egg": MinecraftMaterial(
    name: "Salmon Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/salmon_spawn_egg.png",
  ),
  "sheep_spawn_egg": MinecraftMaterial(
    name: "Sheep Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/sheep_spawn_egg.png",
  ),
  "shulker_spawn_egg": MinecraftMaterial(
    name: "Shulker Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/shulker_spawn_egg.png",
  ),
  "silverfish_spawn_egg": MinecraftMaterial(
    name: "Silverfish Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/silverfish_spawn_egg.png",
  ),
  "skeleton_spawn_egg": MinecraftMaterial(
    name: "Skeleton Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/skeleton_spawn_egg.png",
  ),
  "skeleton_horse_spawn_egg": MinecraftMaterial(
    name: "Skeleton Horse Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/skeleton_horse_spawn_egg.png",
  ),
  "slime_spawn_egg": MinecraftMaterial(
    name: "Slime Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/slime_spawn_egg.png",
  ),
  "spider_spawn_egg": MinecraftMaterial(
    name: "Spider Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/spider_spawn_egg.png",
  ),
  "squid_spawn_egg": MinecraftMaterial(
    name: "Squid Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/squid_spawn_egg.png",
  ),
  "stray_spawn_egg": MinecraftMaterial(
    name: "Stray Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/stray_spawn_egg.png",
  ),
  "strider_spawn_egg": MinecraftMaterial(
    name: "Strider Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/strider_spawn_egg.png",
  ),
  "tadpole_spawn_egg": MinecraftMaterial(
    name: "Tadpole Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/tadpole_spawn_egg.png",
  ),
  "trader_llama_spawn_egg": MinecraftMaterial(
    name: "Trader Llama Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/trader_llama_spawn_egg.png",
  ),
  "tropical_fish_spawn_egg": MinecraftMaterial(
    name: "Tropical Fish Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/tropical_fish_spawn_egg.png",
  ),
  "turtle_spawn_egg": MinecraftMaterial(
    name: "Turtle Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/turtle_spawn_egg.png",
  ),
  "vex_spawn_egg": MinecraftMaterial(
    name: "Vex Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/vex_spawn_egg.png",
  ),
  "villager_spawn_egg": MinecraftMaterial(
    name: "Villager Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/villager_spawn_egg.png",
  ),
  "vindicator_spawn_egg": MinecraftMaterial(
    name: "Vindicator Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/vindicator_spawn_egg.png",
  ),
  "wandering_trader_spawn_egg": MinecraftMaterial(
    name: "Wandering Trader Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/wandering_trader_spawn_egg.png",
  ),
  "warden_spawn_egg": MinecraftMaterial(
    name: "Warden Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/warden_spawn_egg.png",
  ),
  "witch_spawn_egg": MinecraftMaterial(
    name: "Witch Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/witch_spawn_egg.png",
  ),
  "wither_skeleton_spawn_egg": MinecraftMaterial(
    name: "Wither Skeleton Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/wither_skeleton_spawn_egg.png",
  ),
  "wolf_spawn_egg": MinecraftMaterial(
    name: "Wolf Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/wolf_spawn_egg.png",
  ),
  "zoglin_spawn_egg": MinecraftMaterial(
    name: "Zoglin Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/zoglin_spawn_egg.png",
  ),
  "zombie_spawn_egg": MinecraftMaterial(
    name: "Zombie Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/zombie_spawn_egg.png",
  ),
  "zombie_horse_spawn_egg": MinecraftMaterial(
    name: "Zombie Horse Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/zombie_horse_spawn_egg.png",
  ),
  "zombie_villager_spawn_egg": MinecraftMaterial(
    name: "Zombie Villager Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/zombie_villager_spawn_egg.png",
  ),
  "zombified_piglin_spawn_egg": MinecraftMaterial(
    name: "Zombified Piglin Spawn Egg",
    properties: [MaterialProperty.item],
    icon: "assets/materials/zombified_piglin_spawn_egg.png",
  ),
  "experience_bottle": MinecraftMaterial(
    name: "Experience Bottle",
    properties: [MaterialProperty.item],
    icon: "assets/materials/experience_bottle.png",
  ),
  "fire_charge": MinecraftMaterial(
    name: "Fire Charge",
    properties: [MaterialProperty.item],
    icon: "assets/materials/fire_charge.png",
  ),
  "writable_book": MinecraftMaterial(
    name: "Writable Book",
    properties: [MaterialProperty.item],
    icon: "assets/materials/writable_book.png",
  ),
  "written_book": MinecraftMaterial(
    name: "Written Book",
    properties: [MaterialProperty.item],
    icon: "assets/materials/written_book.png",
  ),
  "item_frame": MinecraftMaterial(
    name: "Item Frame",
    properties: [MaterialProperty.item],
    icon: "assets/materials/item_frame.png",
  ),
  "glow_item_frame": MinecraftMaterial(
    name: "Glow Item Frame",
    properties: [MaterialProperty.item],
    icon: "assets/materials/glow_item_frame.png",
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
  "carrot": MinecraftMaterial(
    name: "Carrot",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/carrot.png",
  ),
  "potato": MinecraftMaterial(
    name: "Potato",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/potato.png",
  ),
  "baked_potato": MinecraftMaterial(
    name: "Baked Potato",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/baked_potato.png",
  ),
  "poisonous_potato": MinecraftMaterial(
    name: "Poisonous Potato",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/poisonous_potato.png",
  ),
  "map": MinecraftMaterial(
    name: "Map",
    properties: [MaterialProperty.item],
    icon: "assets/materials/map.png",
  ),
  "golden_carrot": MinecraftMaterial(
    name: "Golden Carrot",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/golden_carrot.png",
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
  "wither_skeleton_skull": MinecraftMaterial(
    name: "Wither Skeleton Skull",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/wither_skeleton_skull.png",
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
  "zombie_head": MinecraftMaterial(
    name: "Zombie Head",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/zombie_head.png",
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
  "dragon_head": MinecraftMaterial(
    name: "Dragon Head",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/dragon_head.png",
  ),
  "nether_star": MinecraftMaterial(
    name: "Nether Star",
    properties: [MaterialProperty.item],
    icon: "assets/materials/nether_star.png",
  ),
  "pumpkin_pie": MinecraftMaterial(
    name: "Pumpkin Pie",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/pumpkin_pie.png",
  ),
  "firework_rocket": MinecraftMaterial(
    name: "Firework Rocket",
    properties: [MaterialProperty.item],
    icon: "assets/materials/firework_rocket.png",
  ),
  "firework_star": MinecraftMaterial(
    name: "Firework Star",
    properties: [MaterialProperty.item],
    icon: "assets/materials/firework_star.png",
  ),
  "enchanted_book": MinecraftMaterial(
    name: "Enchanted Book",
    properties: [MaterialProperty.item],
    icon: "assets/materials/enchanted_book.png",
  ),
  "nether_brick": MinecraftMaterial(
    name: "Nether Brick",
    properties: [MaterialProperty.item],
    icon: "assets/materials/nether_brick.png",
  ),
  "prismarine_shard": MinecraftMaterial(
    name: "Prismarine Shard",
    properties: [MaterialProperty.item],
    icon: "assets/materials/prismarine_shard.png",
  ),
  "prismarine_crystals": MinecraftMaterial(
    name: "Prismarine Crystals",
    properties: [MaterialProperty.item],
    icon: "assets/materials/prismarine_crystals.png",
  ),
  "rabbit": MinecraftMaterial(
    name: "Rabbit",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/rabbit.png",
  ),
  "cooked_rabbit": MinecraftMaterial(
    name: "Cooked Rabbit",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cooked_rabbit.png",
  ),
  "rabbit_stew": MinecraftMaterial(
    name: "Rabbit Stew",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/rabbit_stew.png",
  ),
  "rabbit_foot": MinecraftMaterial(
    name: "Rabbit Foot",
    properties: [MaterialProperty.item],
    icon: "assets/materials/rabbit_foot.png",
  ),
  "rabbit_hide": MinecraftMaterial(
    name: "Rabbit Hide",
    properties: [MaterialProperty.item],
    icon: "assets/materials/rabbit_hide.png",
  ),
  "armor_stand": MinecraftMaterial(
    name: "Armor Stand",
    properties: [MaterialProperty.item],
    icon: "assets/materials/armor_stand.png",
  ),
  "iron_horse_armor": MinecraftMaterial(
    name: "Iron Horse Armor",
    properties: [MaterialProperty.item],
    icon: "assets/materials/iron_horse_armor.png",
  ),
  "golden_horse_armor": MinecraftMaterial(
    name: "Golden Horse Armor",
    properties: [MaterialProperty.item],
    icon: "assets/materials/golden_horse_armor.png",
  ),
  "diamond_horse_armor": MinecraftMaterial(
    name: "Diamond Horse Armor",
    properties: [MaterialProperty.item],
    icon: "assets/materials/diamond_horse_armor.png",
  ),
  "leather_horse_armor": MinecraftMaterial(
    name: "Leather Horse Armor",
    properties: [MaterialProperty.item],
    icon: "assets/materials/leather_horse_armor.png",
  ),
  "lead": MinecraftMaterial(
    name: "Lead",
    properties: [MaterialProperty.item],
    icon: "assets/materials/lead.png",
  ),
  "name_tag": MinecraftMaterial(
    name: "Name Tag",
    properties: [MaterialProperty.item],
    icon: "assets/materials/name_tag.png",
  ),
  "command_block_minecart": MinecraftMaterial(
    name: "Command Block Minecart",
    properties: [MaterialProperty.item],
    icon: "assets/materials/command_block_minecart.png",
  ),
  "mutton": MinecraftMaterial(
    name: "Mutton",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/mutton.png",
  ),
  "cooked_mutton": MinecraftMaterial(
    name: "Cooked Mutton",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/cooked_mutton.png",
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
  "end_crystal": MinecraftMaterial(
    name: "End Crystal",
    properties: [MaterialProperty.item],
    icon: "assets/materials/end_crystal.png",
  ),
  "chorus_fruit": MinecraftMaterial(
    name: "Chorus Fruit",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/chorus_fruit.png",
  ),
  "popped_chorus_fruit": MinecraftMaterial(
    name: "Popped Chorus Fruit",
    properties: [MaterialProperty.item],
    icon: "assets/materials/popped_chorus_fruit.png",
  ),
  "beetroot": MinecraftMaterial(
    name: "Beetroot",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/beetroot.png",
  ),
  "beetroot_seeds": MinecraftMaterial(
    name: "Beetroot Seeds",
    properties: [MaterialProperty.item],
    icon: "assets/materials/beetroot_seeds.png",
  ),
  "beetroot_soup": MinecraftMaterial(
    name: "Beetroot Soup",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/beetroot_soup.png",
  ),
  "dragon_breath": MinecraftMaterial(
    name: "Dragon Breath",
    properties: [MaterialProperty.item],
    icon: "assets/materials/dragon_breath.png",
  ),
  "splash_potion": MinecraftMaterial(
    name: "Splash Potion",
    properties: [MaterialProperty.item],
    icon: "assets/materials/splash_potion.png",
  ),
  "spectral_arrow": MinecraftMaterial(
    name: "Spectral Arrow",
    properties: [MaterialProperty.item],
    icon: "assets/materials/spectral_arrow.png",
  ),
  "tipped_arrow": MinecraftMaterial(
    name: "Tipped Arrow",
    properties: [MaterialProperty.item],
    icon: "assets/materials/tipped_arrow.png",
  ),
  "lingering_potion": MinecraftMaterial(
    name: "Lingering Potion",
    properties: [MaterialProperty.item],
    icon: "assets/materials/lingering_potion.png",
  ),
  "shield": MinecraftMaterial(
    name: "Shield",
    properties: [MaterialProperty.item],
    icon: "assets/materials/shield.png",
  ),
  "totem_of_undying": MinecraftMaterial(
    name: "Totem Of Undying",
    properties: [MaterialProperty.item],
    icon: "assets/materials/totem_of_undying.png",
  ),
  "shulker_shell": MinecraftMaterial(
    name: "Shulker Shell",
    properties: [MaterialProperty.item],
    icon: "assets/materials/shulker_shell.png",
  ),
  "iron_nugget": MinecraftMaterial(
    name: "Iron Nugget",
    properties: [MaterialProperty.item],
    icon: "assets/materials/iron_nugget.png",
  ),
  "knowledge_book": MinecraftMaterial(
    name: "Knowledge Book",
    properties: [MaterialProperty.item],
    icon: "assets/materials/knowledge_book.png",
  ),
  "debug_stick": MinecraftMaterial(
    name: "Debug Stick",
    properties: [MaterialProperty.item],
    icon: "assets/materials/debug_stick.png",
  ),
  "music_disc_13": MinecraftMaterial(
    name: "Music Disc 13",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_13.png",
  ),
  "music_disc_cat": MinecraftMaterial(
    name: "Music Disc Cat",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_cat.png",
  ),
  "music_disc_blocks": MinecraftMaterial(
    name: "Music Disc Blocks",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_blocks.png",
  ),
  "music_disc_chirp": MinecraftMaterial(
    name: "Music Disc Chirp",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_chirp.png",
  ),
  "music_disc_far": MinecraftMaterial(
    name: "Music Disc Far",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_far.png",
  ),
  "music_disc_mall": MinecraftMaterial(
    name: "Music Disc Mall",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_mall.png",
  ),
  "music_disc_mellohi": MinecraftMaterial(
    name: "Music Disc Mellohi",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_mellohi.png",
  ),
  "music_disc_stal": MinecraftMaterial(
    name: "Music Disc Stal",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_stal.png",
  ),
  "music_disc_strad": MinecraftMaterial(
    name: "Music Disc Strad",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_strad.png",
  ),
  "music_disc_ward": MinecraftMaterial(
    name: "Music Disc Ward",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_ward.png",
  ),
  "music_disc_11": MinecraftMaterial(
    name: "Music Disc 11",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_11.png",
  ),
  "music_disc_wait": MinecraftMaterial(
    name: "Music Disc Wait",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_wait.png",
  ),
  "music_disc_otherside": MinecraftMaterial(
    name: "Music Disc Otherside",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_otherside.png",
  ),
  "music_disc_5": MinecraftMaterial(
    name: "Music Disc 5",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_5.png",
  ),
  "music_disc_pigstep": MinecraftMaterial(
    name: "Music Disc Pigstep",
    properties: [MaterialProperty.item, MaterialProperty.record],
    icon: "assets/materials/music_disc_pigstep.png",
  ),
  "disc_fragment_5": MinecraftMaterial(
    name: "Disc Fragment 5",
    properties: [MaterialProperty.item],
    icon: "assets/materials/disc_fragment_5.png",
  ),
  "trident": MinecraftMaterial(
    name: "Trident",
    properties: [MaterialProperty.item],
    icon: "assets/materials/trident.png",
  ),
  "phantom_membrane": MinecraftMaterial(
    name: "Phantom Membrane",
    properties: [MaterialProperty.item],
    icon: "assets/materials/phantom_membrane.png",
  ),
  "nautilus_shell": MinecraftMaterial(
    name: "Nautilus Shell",
    properties: [MaterialProperty.item],
    icon: "assets/materials/nautilus_shell.png",
  ),
  "heart_of_the_sea": MinecraftMaterial(
    name: "Heart Of The Sea",
    properties: [MaterialProperty.item],
    icon: "assets/materials/heart_of_the_sea.png",
  ),
  "crossbow": MinecraftMaterial(
    name: "Crossbow",
    properties: [MaterialProperty.item, MaterialProperty.fuel],
    icon: "assets/materials/crossbow.png",
  ),
  "suspicious_stew": MinecraftMaterial(
    name: "Suspicious Stew",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/suspicious_stew.png",
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
  "flower_banner_pattern": MinecraftMaterial(
    name: "Flower Banner Pattern",
    properties: [MaterialProperty.item],
    icon: "assets/materials/flower_banner_pattern.png",
  ),
  "creeper_banner_pattern": MinecraftMaterial(
    name: "Creeper Banner Pattern",
    properties: [MaterialProperty.item],
    icon: "assets/materials/creeper_banner_pattern.png",
  ),
  "skull_banner_pattern": MinecraftMaterial(
    name: "Skull Banner Pattern",
    properties: [MaterialProperty.item],
    icon: "assets/materials/skull_banner_pattern.png",
  ),
  "mojang_banner_pattern": MinecraftMaterial(
    name: "Mojang Banner Pattern",
    properties: [MaterialProperty.item],
    icon: "assets/materials/mojang_banner_pattern.png",
  ),
  "globe_banner_pattern": MinecraftMaterial(
    name: "Globe Banner Pattern",
    properties: [MaterialProperty.item],
    icon: "assets/materials/globe_banner_pattern.png",
  ),
  "piglin_banner_pattern": MinecraftMaterial(
    name: "Piglin Banner Pattern",
    properties: [MaterialProperty.item],
    icon: "assets/materials/piglin_banner_pattern.png",
  ),
  "goat_horn": MinecraftMaterial(
    name: "Goat Horn",
    properties: [MaterialProperty.item],
    icon: "assets/materials/goat_horn.png",
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
  "lantern": MinecraftMaterial(
    name: "Lantern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lantern.png",
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
  "sweet_berries": MinecraftMaterial(
    name: "Sweet Berries",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/sweet_berries.png",
  ),
  "glow_berries": MinecraftMaterial(
    name: "Glow Berries",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/glow_berries.png",
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
  "honeycomb": MinecraftMaterial(
    name: "Honeycomb",
    properties: [MaterialProperty.item],
    icon: "assets/materials/honeycomb.png",
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
  "honey_bottle": MinecraftMaterial(
    name: "Honey Bottle",
    properties: [MaterialProperty.item, MaterialProperty.edible],
    icon: "assets/materials/honey_bottle.png",
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
  "candle": MinecraftMaterial(
    name: "Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/candle.png",
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
  "orange_candle": MinecraftMaterial(
    name: "Orange Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/orange_candle.png",
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
  "light_blue_candle": MinecraftMaterial(
    name: "Light Blue Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/light_blue_candle.png",
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
  "lime_candle": MinecraftMaterial(
    name: "Lime Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/lime_candle.png",
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
  "gray_candle": MinecraftMaterial(
    name: "Gray Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/gray_candle.png",
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
  "cyan_candle": MinecraftMaterial(
    name: "Cyan Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/cyan_candle.png",
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
  "blue_candle": MinecraftMaterial(
    name: "Blue Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/blue_candle.png",
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
  "green_candle": MinecraftMaterial(
    name: "Green Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/green_candle.png",
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
  "black_candle": MinecraftMaterial(
    name: "Black Candle",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.intractable,
    ],
    icon: "assets/materials/black_candle.png",
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
  "medium_amethyst_bud": MinecraftMaterial(
    name: "Medium Amethyst Bud",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/medium_amethyst_bud.png",
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
  "amethyst_cluster": MinecraftMaterial(
    name: "Amethyst Cluster",
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/amethyst_cluster.png",
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
  "frogspawn": MinecraftMaterial(
    name: "Frogspawn",
    properties: [MaterialProperty.block, MaterialProperty.item],
    icon: "assets/materials/frogspawn.png",
  ),
  "echo_shard": MinecraftMaterial(
    name: "Echo Shard",
    properties: [MaterialProperty.item],
    icon: "assets/materials/echo_shard.png",
  ),
  "water": MinecraftMaterial(
    name: "Water",
    properties: [MaterialProperty.block],
    icon: "assets/materials/water.webp",
  ),
  "lava": MinecraftMaterial(
    name: "Lava",
    properties: [MaterialProperty.block],
    icon: "assets/materials/lava.webp",
  ),
  "tall_seagrass": MinecraftMaterial(
    name: "Tall Seagrass",
    properties: [MaterialProperty.block],
    icon: "assets/materials/tall_seagrass.png",
  ),
  "piston_head": MinecraftMaterial(
    name: "Piston Head",
    properties: [MaterialProperty.block, MaterialProperty.solid],
    icon: "assets/materials/piston_head.webp",
  ),
  "moving_piston": MinecraftMaterial(
    name: "Moving Piston",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/moving_piston.png",
  ),
  "wall_torch": MinecraftMaterial(
    name: "Wall Torch",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/wall_torch.png",
  ),
  "fire": MinecraftMaterial(
    name: "Fire",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/fire.webp",
  ),
  "soul_fire": MinecraftMaterial(
    name: "Soul Fire",
    properties: [MaterialProperty.block],
    icon: "assets/materials/soul_fire.webp",
  ),
  "redstone_wire": MinecraftMaterial(
    name: "Redstone Wire",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/redstone_wire.webp",
  ),
  "oak_wall_sign": MinecraftMaterial(
    name: "Oak Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/oak_wall_sign.png",
  ),
  "spruce_wall_sign": MinecraftMaterial(
    name: "Spruce Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/spruce_wall_sign.png",
  ),
  "birch_wall_sign": MinecraftMaterial(
    name: "Birch Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/birch_wall_sign.png",
  ),
  "acacia_wall_sign": MinecraftMaterial(
    name: "Acacia Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/acacia_wall_sign.png",
  ),
  "jungle_wall_sign": MinecraftMaterial(
    name: "Jungle Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/jungle_wall_sign.png",
  ),
  "dark_oak_wall_sign": MinecraftMaterial(
    name: "Dark Oak Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/dark_oak_wall_sign.png",
  ),
  "mangrove_wall_sign": MinecraftMaterial(
    name: "Mangrove Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/mangrove_wall_sign.png",
  ),
  "redstone_wall_torch": MinecraftMaterial(
    name: "Redstone Wall Torch",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/redstone_wall_torch.png",
  ),
  "soul_wall_torch": MinecraftMaterial(
    name: "Soul Wall Torch",
    properties: [MaterialProperty.block],
    icon: "assets/materials/soul_wall_torch.png",
  ),
  "nether_portal": MinecraftMaterial(
    name: "Nether Portal",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/nether_portal.webp",
  ),
  "attached_pumpkin_stem": MinecraftMaterial(
    name: "Attached Pumpkin Stem",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/attached_pumpkin_stem.png",
  ),
  "attached_melon_stem": MinecraftMaterial(
    name: "Attached Melon Stem",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/attached_melon_stem.png",
  ),
  "pumpkin_stem": MinecraftMaterial(
    name: "Pumpkin Stem",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/pumpkin_stem.png",
  ),
  "melon_stem": MinecraftMaterial(
    name: "Melon Stem",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/melon_stem.png",
  ),
  "water_cauldron": MinecraftMaterial(
    name: "Water Cauldron",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/water_cauldron.webp",
  ),
  "lava_cauldron": MinecraftMaterial(
    name: "Lava Cauldron",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lava_cauldron.webp",
  ),
  "powder_snow_cauldron": MinecraftMaterial(
    name: "Powder Snow Cauldron",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/powder_snow_cauldron.webp",
  ),
  "end_portal": MinecraftMaterial(
    name: "End Portal",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/end_portal.webp",
  ),
  "cocoa": MinecraftMaterial(
    name: "Cocoa",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/cocoa.webp",
  ),
  "tripwire": MinecraftMaterial(
    name: "Tripwire",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/tripwire.png",
  ),
  "potted_oak_sapling": MinecraftMaterial(
    name: "Potted Oak Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_oak_sapling.png",
  ),
  "potted_spruce_sapling": MinecraftMaterial(
    name: "Potted Spruce Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_spruce_sapling.webp",
  ),
  "potted_birch_sapling": MinecraftMaterial(
    name: "Potted Birch Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_birch_sapling.webp",
  ),
  "potted_jungle_sapling": MinecraftMaterial(
    name: "Potted Jungle Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_jungle_sapling.webp",
  ),
  "potted_acacia_sapling": MinecraftMaterial(
    name: "Potted Acacia Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_acacia_sapling.webp",
  ),
  "potted_dark_oak_sapling": MinecraftMaterial(
    name: "Potted Dark Oak Sapling",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_dark_oak_sapling.webp",
  ),
  "potted_mangrove_propagule": MinecraftMaterial(
    name: "Potted Mangrove Propagule",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_mangrove_propagule.webp",
  ),
  "potted_fern": MinecraftMaterial(
    name: "Potted Fern",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_fern.webp",
  ),
  "potted_dandelion": MinecraftMaterial(
    name: "Potted Dandelion",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_dandelion.png",
  ),
  "potted_poppy": MinecraftMaterial(
    name: "Potted Poppy",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_poppy.webp",
  ),
  "potted_blue_orchid": MinecraftMaterial(
    name: "Potted Blue Orchid",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_blue_orchid.webp",
  ),
  "potted_allium": MinecraftMaterial(
    name: "Potted Allium",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_allium.webp",
  ),
  "potted_azure_bluet": MinecraftMaterial(
    name: "Potted Azure Bluet",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_azure_bluet.webp",
  ),
  "potted_red_tulip": MinecraftMaterial(
    name: "Potted Red Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_red_tulip.webp",
  ),
  "potted_orange_tulip": MinecraftMaterial(
    name: "Potted Orange Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_orange_tulip.png",
  ),
  "potted_white_tulip": MinecraftMaterial(
    name: "Potted White Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_white_tulip.png",
  ),
  "potted_pink_tulip": MinecraftMaterial(
    name: "Potted Pink Tulip",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_pink_tulip.webp",
  ),
  "potted_oxeye_daisy": MinecraftMaterial(
    name: "Potted Oxeye Daisy",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_oxeye_daisy.png",
  ),
  "potted_cornflower": MinecraftMaterial(
    name: "Potted Cornflower",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_cornflower.webp",
  ),
  "potted_lily_of_the_valley": MinecraftMaterial(
    name: "Potted Lily Of The Valley",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_lily_of_the_valley.webp",
  ),
  "potted_wither_rose": MinecraftMaterial(
    name: "Potted Wither Rose",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_wither_rose.webp",
  ),
  "potted_red_mushroom": MinecraftMaterial(
    name: "Potted Red Mushroom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_red_mushroom.png",
  ),
  "potted_brown_mushroom": MinecraftMaterial(
    name: "Potted Brown Mushroom",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_brown_mushroom.webp",
  ),
  "potted_dead_bush": MinecraftMaterial(
    name: "Potted Dead Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_dead_bush.webp",
  ),
  "potted_cactus": MinecraftMaterial(
    name: "Potted Cactus",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_cactus.webp",
  ),
  "carrots": MinecraftMaterial(
    name: "Carrots",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/carrots.png",
  ),
  "potatoes": MinecraftMaterial(
    name: "Potatoes",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/potatoes.png",
  ),
  "skeleton_wall_skull": MinecraftMaterial(
    name: "Skeleton Wall Skull",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/skeleton_wall_skull.png",
  ),
  "wither_skeleton_wall_skull": MinecraftMaterial(
    name: "Wither Skeleton Wall Skull",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/wither_skeleton_wall_skull.png",
  ),
  "zombie_wall_head": MinecraftMaterial(
    name: "Zombie Wall Head",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/zombie_wall_head.png",
  ),
  "player_wall_head": MinecraftMaterial(
    name: "Player Wall Head",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/player_wall_head.png",
  ),
  "creeper_wall_head": MinecraftMaterial(
    name: "Creeper Wall Head",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/creeper_wall_head.png",
  ),
  "dragon_wall_head": MinecraftMaterial(
    name: "Dragon Wall Head",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/dragon_wall_head.png",
  ),
  "white_wall_banner": MinecraftMaterial(
    name: "White Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/white_wall_banner.png",
  ),
  "orange_wall_banner": MinecraftMaterial(
    name: "Orange Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/orange_wall_banner.png",
  ),
  "magenta_wall_banner": MinecraftMaterial(
    name: "Magenta Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/magenta_wall_banner.png",
  ),
  "light_blue_wall_banner": MinecraftMaterial(
    name: "Light Blue Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_blue_wall_banner.png",
  ),
  "yellow_wall_banner": MinecraftMaterial(
    name: "Yellow Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/yellow_wall_banner.png",
  ),
  "lime_wall_banner": MinecraftMaterial(
    name: "Lime Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/lime_wall_banner.png",
  ),
  "pink_wall_banner": MinecraftMaterial(
    name: "Pink Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/pink_wall_banner.png",
  ),
  "gray_wall_banner": MinecraftMaterial(
    name: "Gray Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/gray_wall_banner.png",
  ),
  "light_gray_wall_banner": MinecraftMaterial(
    name: "Light Gray Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/light_gray_wall_banner.png",
  ),
  "cyan_wall_banner": MinecraftMaterial(
    name: "Cyan Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/cyan_wall_banner.png",
  ),
  "purple_wall_banner": MinecraftMaterial(
    name: "Purple Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/purple_wall_banner.png",
  ),
  "blue_wall_banner": MinecraftMaterial(
    name: "Blue Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/blue_wall_banner.png",
  ),
  "brown_wall_banner": MinecraftMaterial(
    name: "Brown Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/brown_wall_banner.png",
  ),
  "green_wall_banner": MinecraftMaterial(
    name: "Green Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/green_wall_banner.png",
  ),
  "red_wall_banner": MinecraftMaterial(
    name: "Red Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/red_wall_banner.png",
  ),
  "black_wall_banner": MinecraftMaterial(
    name: "Black Wall Banner",
    properties: [
      MaterialProperty.block,
      MaterialProperty.solid,
      MaterialProperty.flammable,
    ],
    icon: "assets/materials/black_wall_banner.png",
  ),
  "beetroots": MinecraftMaterial(
    name: "Beetroots",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/beetroots.png",
  ),
  "end_gateway": MinecraftMaterial(
    name: "End Gateway",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/end_gateway.webp",
  ),
  "frosted_ice": MinecraftMaterial(
    name: "Frosted Ice",
    properties: [MaterialProperty.block, MaterialProperty.solid],
    icon: "assets/materials/frosted_ice.webp",
  ),
  "kelp_plant": MinecraftMaterial(
    name: "Kelp Plant",
    properties: [MaterialProperty.block],
    icon: "assets/materials/kelp_plant.webp",
  ),
  "dead_tube_coral_wall_fan": MinecraftMaterial(
    name: "Dead Tube Coral Wall Fan",
    properties: [MaterialProperty.block, MaterialProperty.solid],
    icon: "assets/materials/dead_tube_coral_wall_fan.webp",
  ),
  "dead_brain_coral_wall_fan": MinecraftMaterial(
    name: "Dead Brain Coral Wall Fan",
    properties: [MaterialProperty.block, MaterialProperty.solid],
    icon: "assets/materials/dead_brain_coral_wall_fan.webp",
  ),
  "dead_bubble_coral_wall_fan": MinecraftMaterial(
    name: "Dead Bubble Coral Wall Fan",
    properties: [MaterialProperty.block, MaterialProperty.solid],
    icon: "assets/materials/dead_bubble_coral_wall_fan.webp",
  ),
  "dead_fire_coral_wall_fan": MinecraftMaterial(
    name: "Dead Fire Coral Wall Fan",
    properties: [MaterialProperty.block, MaterialProperty.solid],
    icon: "assets/materials/dead_fire_coral_wall_fan.webp",
  ),
  "dead_horn_coral_wall_fan": MinecraftMaterial(
    name: "Dead Horn Coral Wall Fan",
    properties: [MaterialProperty.block, MaterialProperty.solid],
    icon: "assets/materials/dead_horn_coral_wall_fan.webp",
  ),
  "tube_coral_wall_fan": MinecraftMaterial(
    name: "Tube Coral Wall Fan",
    properties: [MaterialProperty.block],
    icon: "assets/materials/tube_coral_wall_fan.png",
  ),
  "brain_coral_wall_fan": MinecraftMaterial(
    name: "Brain Coral Wall Fan",
    properties: [MaterialProperty.block],
    icon: "assets/materials/brain_coral_wall_fan.png",
  ),
  "bubble_coral_wall_fan": MinecraftMaterial(
    name: "Bubble Coral Wall Fan",
    properties: [MaterialProperty.block],
    icon: "assets/materials/bubble_coral_wall_fan.png",
  ),
  "fire_coral_wall_fan": MinecraftMaterial(
    name: "Fire Coral Wall Fan",
    properties: [MaterialProperty.block],
    icon: "assets/materials/fire_coral_wall_fan.png",
  ),
  "horn_coral_wall_fan": MinecraftMaterial(
    name: "Horn Coral Wall Fan",
    properties: [MaterialProperty.block],
    icon: "assets/materials/horn_coral_wall_fan.png",
  ),
  "bamboo_sapling": MinecraftMaterial(
    name: "Bamboo Sapling",
    properties: [MaterialProperty.block, MaterialProperty.flammable],
    icon: "assets/materials/bamboo_sapling.webp",
  ),
  "potted_bamboo": MinecraftMaterial(
    name: "Potted Bamboo",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_bamboo.png",
  ),
  "void_air": MinecraftMaterial(
    name: "Void Air",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/void_air.png",
  ),
  "cave_air": MinecraftMaterial(
    name: "Cave Air",
    properties: [MaterialProperty.block, MaterialProperty.transparent],
    icon: "assets/materials/cave_air.png",
  ),
  "bubble_column": MinecraftMaterial(
    name: "Bubble Column",
    properties: [MaterialProperty.block],
    icon: "assets/materials/bubble_column.webp",
  ),
  "sweet_berry_bush": MinecraftMaterial(
    name: "Sweet Berry Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/sweet_berry_bush.webp",
  ),
  "weeping_vines_plant": MinecraftMaterial(
    name: "Weeping Vines Plant",
    properties: [MaterialProperty.block],
    icon: "assets/materials/weeping_vines_plant.webp",
  ),
  "twisting_vines_plant": MinecraftMaterial(
    name: "Twisting Vines Plant",
    properties: [MaterialProperty.block],
    icon: "assets/materials/twisting_vines_plant.webp",
  ),
  "crimson_wall_sign": MinecraftMaterial(
    name: "Crimson Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/crimson_wall_sign.png",
  ),
  "warped_wall_sign": MinecraftMaterial(
    name: "Warped Wall Sign",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/warped_wall_sign.png",
  ),
  "potted_crimson_fungus": MinecraftMaterial(
    name: "Potted Crimson Fungus",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_crimson_fungus.png",
  ),
  "potted_warped_fungus": MinecraftMaterial(
    name: "Potted Warped Fungus",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_warped_fungus.png",
  ),
  "potted_crimson_roots": MinecraftMaterial(
    name: "Potted Crimson Roots",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_crimson_roots.webp",
  ),
  "potted_warped_roots": MinecraftMaterial(
    name: "Potted Warped Roots",
    properties: [MaterialProperty.block, MaterialProperty.intractable],
    icon: "assets/materials/potted_warped_roots.png",
  ),
  "candle_cake": MinecraftMaterial(
    name: "Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/candle_cake.webp",
  ),
  "white_candle_cake": MinecraftMaterial(
    name: "White Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/white_candle_cake.webp",
  ),
  "orange_candle_cake": MinecraftMaterial(
    name: "Orange Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/orange_candle_cake.webp",
  ),
  "magenta_candle_cake": MinecraftMaterial(
    name: "Magenta Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/magenta_candle_cake.webp",
  ),
  "light_blue_candle_cake": MinecraftMaterial(
    name: "Light Blue Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_blue_candle_cake.webp",
  ),
  "yellow_candle_cake": MinecraftMaterial(
    name: "Yellow Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/yellow_candle_cake.png",
  ),
  "lime_candle_cake": MinecraftMaterial(
    name: "Lime Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/lime_candle_cake.webp",
  ),
  "pink_candle_cake": MinecraftMaterial(
    name: "Pink Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/pink_candle_cake.webp",
  ),
  "gray_candle_cake": MinecraftMaterial(
    name: "Gray Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/gray_candle_cake.webp",
  ),
  "light_gray_candle_cake": MinecraftMaterial(
    name: "Light Gray Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/light_gray_candle_cake.webp",
  ),
  "cyan_candle_cake": MinecraftMaterial(
    name: "Cyan Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/cyan_candle_cake.webp",
  ),
  "purple_candle_cake": MinecraftMaterial(
    name: "Purple Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/purple_candle_cake.webp",
  ),
  "blue_candle_cake": MinecraftMaterial(
    name: "Blue Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/blue_candle_cake.webp",
  ),
  "brown_candle_cake": MinecraftMaterial(
    name: "Brown Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/brown_candle_cake.webp",
  ),
  "green_candle_cake": MinecraftMaterial(
    name: "Green Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/green_candle_cake.webp",
  ),
  "red_candle_cake": MinecraftMaterial(
    name: "Red Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/red_candle_cake.webp",
  ),
  "black_candle_cake": MinecraftMaterial(
    name: "Black Candle Cake",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.solid,
    ],
    icon: "assets/materials/black_candle_cake.webp",
  ),
  "powder_snow": MinecraftMaterial(
    name: "Powder Snow",
    properties: [MaterialProperty.block],
    icon: "assets/materials/powder_snow.webp",
  ),
  "cave_vines": MinecraftMaterial(
    name: "Cave Vines",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/cave_vines.webp",
  ),
  "cave_vines_plant": MinecraftMaterial(
    name: "Cave Vines Plant",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.burnable,
    ],
    icon: "assets/materials/cave_vines_plant.webp",
  ),
  "big_dripleaf_stem": MinecraftMaterial(
    name: "Big Dripleaf Stem",
    properties: [MaterialProperty.block, MaterialProperty.burnable],
    icon: "assets/materials/big_dripleaf_stem.webp",
  ),
  "potted_azalea_bush": MinecraftMaterial(
    name: "Potted Azalea Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_azalea_bush.webp",
  ),
  "potted_flowering_azalea_bush": MinecraftMaterial(
    name: "Potted Flowering Azalea Bush",
    properties: [
      MaterialProperty.block,
      MaterialProperty.intractable,
      MaterialProperty.transparent,
    ],
    icon: "assets/materials/potted_flowering_azalea_bush.png",
  ),
  "black_bundle": MinecraftMaterial(
    name: "Black Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/black_bundle.png",
  ),
  "black_harness": MinecraftMaterial(
    name: "Black Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/black_harness.png",
  ),
  "blue_bundle": MinecraftMaterial(
    name: "Blue Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blue_bundle.png",
  ),
  "blue_harness": MinecraftMaterial(
    name: "Blue Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/blue_harness.png",
  ),
  "brown_bundle": MinecraftMaterial(
    name: "Brown Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brown_bundle.png",
  ),
  "brown_harness": MinecraftMaterial(
    name: "Brown Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/brown_harness.png",
  ),
  "bundle": MinecraftMaterial(
    name: "Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/bundle.png",
  ),
  "bush": MinecraftMaterial(
    name: "Bush",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/bush.png",
  ),
  "cactus_flower": MinecraftMaterial(
    name: "Cactus Flower",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/cactus_flower.png",
  ),
  "chiseled_resin_bricks": MinecraftMaterial(
    name: "Chiseled Resin Bricks",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/chiseled_resin_bricks.png",
  ),
  "closed_eyeblossom": MinecraftMaterial(
    name: "Closed Eyeblossom",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/closed_eyeblossom.png",
  ),
  "copper_bulb": MinecraftMaterial(
    name: "Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_bulb.png",
  ),
  "copper_door": MinecraftMaterial(
    name: "Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_door.png",
  ),
  "copper_grate": MinecraftMaterial(
    name: "Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_grate.png",
  ),
  "copper_trapdoor": MinecraftMaterial(
    name: "Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_trapdoor.png",
  ),
  "copper_chain": MinecraftMaterial(
    name: "Copper Chain",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_chain.png",
  ),
  "copper_lantern": MinecraftMaterial(
    name: "Copper Lantern",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_lantern.png",
  ),
  "copper_pickaxe": MinecraftMaterial(
    name: "Copper Pickaxe",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_pickaxe.png",
  ),
  "copper_axe": MinecraftMaterial(
    name: "Copper Axe",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_axe.png",
  ),
  "copper_shovel": MinecraftMaterial(
    name: "Copper Shovel",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_shovel.png",
  ),
  "copper_hoe": MinecraftMaterial(
    name: "Copper Hoe",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_hoe.png",
  ),
  "copper_sword": MinecraftMaterial(
    name: "Copper Sword",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.weapon,
      MaterialProperty.tool,
    ],
    icon: "assets/materials/copper_sword.png",
  ),
  "copper_helmet": MinecraftMaterial(
    name: "Copper Helmet",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_helmet.png",
  ),
  "copper_chestplate": MinecraftMaterial(
    name: "Copper Chestplate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_chestplate.png",
  ),
  "copper_leggings": MinecraftMaterial(
    name: "Copper Leggings",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_leggings.png",
  ),
  "copper_boots": MinecraftMaterial(
    name: "Copper Boots",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_boots.png",
  ),
  "copper_horse_armor": MinecraftMaterial(
    name: "Copper Horse Armor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
      MaterialProperty.armor,
    ],
    icon: "assets/materials/copper_horse_armor.png",
  ),
  "copper_nugget": MinecraftMaterial(
    name: "Copper Nugget",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_nugget.png",
  ),
  "copper_golem_spawn_egg": MinecraftMaterial(
    name: "Copper Golem Spawn Egg",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/copper_golem_spawn_egg.png",
  ),
  "creaking_heart": MinecraftMaterial(
    name: "Creaking Heart",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/creaking_heart.png",
  ),
  "creaking_spawn_egg": MinecraftMaterial(
    name: "Creaking Spawn Egg",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/creaking_spawn_egg.png",
  ),
  "cyan_bundle": MinecraftMaterial(
    name: "Cyan Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cyan_bundle.png",
  ),
  "cyan_harness": MinecraftMaterial(
    name: "Cyan Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/cyan_harness.png",
  ),
  "dried_ghast": MinecraftMaterial(
    name: "Dried Ghast",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/dried_ghast.png",
  ),
  "exposed_copper_bulb": MinecraftMaterial(
    name: "Exposed Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_bulb.png",
  ),
  "exposed_copper_door": MinecraftMaterial(
    name: "Exposed Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_door.png",
  ),
  "exposed_copper_grate": MinecraftMaterial(
    name: "Exposed Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_grate.png",
  ),
  "exposed_copper_trapdoor": MinecraftMaterial(
    name: "Exposed Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_trapdoor.png",
  ),
  "exposed_copper_chain": MinecraftMaterial(
    name: "Exposed Copper Chain",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_chain.png",
  ),
  "exposed_copper_lantern": MinecraftMaterial(
    name: "Exposed Copper Lantern",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/exposed_copper_lantern.png",
  ),
  "firefly_bush": MinecraftMaterial(
    name: "Firefly Bush",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/firefly_bush.png",
  ),
  "gray_bundle": MinecraftMaterial(
    name: "Gray Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gray_bundle.png",
  ),
  "gray_harness": MinecraftMaterial(
    name: "Gray Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/gray_harness.png",
  ),
  "green_bundle": MinecraftMaterial(
    name: "Green Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/green_bundle.png",
  ),
  "green_harness": MinecraftMaterial(
    name: "Green Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/green_harness.png",
  ),
  "happy_ghast_spawn_egg": MinecraftMaterial(
    name: "Happy Ghast Spawn Egg",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/happy_ghast_spawn_egg.png",
  ),
  "leaf_litter": MinecraftMaterial(
    name: "Leaf Litter",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/leaf_litter.png",
  ),
  "light_blue_bundle": MinecraftMaterial(
    name: "Light Blue Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_blue_bundle.png",
  ),
  "light_blue_harness": MinecraftMaterial(
    name: "Light Blue Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_blue_harness.png",
  ),
  "light_gray_bundle": MinecraftMaterial(
    name: "Light Gray Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_gray_bundle.png",
  ),
  "light_gray_harness": MinecraftMaterial(
    name: "Light Gray Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/light_gray_harness.png",
  ),
  "lime_bundle": MinecraftMaterial(
    name: "Lime Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lime_bundle.png",
  ),
  "lime_harness": MinecraftMaterial(
    name: "Lime Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/lime_harness.png",
  ),
  "magenta_bundle": MinecraftMaterial(
    name: "Magenta Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/magenta_bundle.png",
  ),
  "magenta_harness": MinecraftMaterial(
    name: "Magenta Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/magenta_harness.png",
  ),
  "music_disc_lava_chicken": MinecraftMaterial(
    name: "Music Disc",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_lava_chicken.png",
  ),
  "music_disc_tears": MinecraftMaterial(
    name: "Music Disc",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/music_disc_tears.png",
  ),
  "open_eyeblossom": MinecraftMaterial(
    name: "Open Eyeblossom",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/open_eyeblossom.png",
  ),
  "orange_bundle": MinecraftMaterial(
    name: "Orange Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/orange_bundle.png",
  ),
  "orange_harness": MinecraftMaterial(
    name: "Orange Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/orange_harness.png",
  ),
  "oxidized_copper_bulb": MinecraftMaterial(
    name: "Oxidized Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_bulb.png",
  ),
  "oxidized_copper_door": MinecraftMaterial(
    name: "Oxidized Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_door.png",
  ),
  "oxidized_copper_grate": MinecraftMaterial(
    name: "Oxidized Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_grate.png",
  ),
  "oxidized_copper_trapdoor": MinecraftMaterial(
    name: "Oxidized Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_trapdoor.png",
  ),
  "oxidized_copper_chain": MinecraftMaterial(
    name: "Oxidized Copper Chain",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_chain.png",
  ),
  "oxidized_copper_lantern": MinecraftMaterial(
    name: "Oxidized Copper Lantern",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/oxidized_copper_lantern.png",
  ),
  "pale_hanging_moss": MinecraftMaterial(
    name: "Pale Hanging Moss",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_hanging_moss.png",
  ),
  "pale_moss_block": MinecraftMaterial(
    name: "Pale Moss Block",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_moss_block.png",
  ),
  "pale_moss_carpet": MinecraftMaterial(
    name: "Pale Moss Carpet",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_moss_carpet.png",
  ),
  "pale_oak_boat": MinecraftMaterial(
    name: "Pale Oak Boat",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_boat.png",
  ),
  "pale_oak_button": MinecraftMaterial(
    name: "Pale Oak Button",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_button.png",
  ),
  "pale_oak_chest_boat": MinecraftMaterial(
    name: "Pale Oak Boat with Chest",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_chest_boat.png",
  ),
  "pale_oak_door": MinecraftMaterial(
    name: "Pale Oak Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_door.png",
  ),
  "pale_oak_fence": MinecraftMaterial(
    name: "Pale Oak Fence",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_fence.png",
  ),
  "pale_oak_fence_gate": MinecraftMaterial(
    name: "Pale Oak Fence Gate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_fence_gate.png",
  ),
  "pale_oak_hanging_sign": MinecraftMaterial(
    name: "Pale Oak Hanging Sign",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_hanging_sign.png",
  ),
  "pale_oak_leaves": MinecraftMaterial(
    name: "Pale Oak Leaves",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_leaves.png",
  ),
  "pale_oak_log": MinecraftMaterial(
    name: "Pale Oak Log",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_log.png",
  ),
  "pale_oak_planks": MinecraftMaterial(
    name: "Pale Oak Planks",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_planks.png",
  ),
  "pale_oak_pressure_plate": MinecraftMaterial(
    name: "Pale Oak Pressure Plate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_pressure_plate.png",
  ),
  "pale_oak_sapling": MinecraftMaterial(
    name: "Pale Oak Sapling",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_sapling.png",
  ),
  "pale_oak_sign": MinecraftMaterial(
    name: "Pale Oak Sign",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_sign.png",
  ),
  "pale_oak_slab": MinecraftMaterial(
    name: "Pale Oak Slab",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_slab.png",
  ),
  "pale_oak_stairs": MinecraftMaterial(
    name: "Pale Oak Stairs",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_stairs.png",
  ),
  "pale_oak_trapdoor": MinecraftMaterial(
    name: "Pale Oak Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_trapdoor.png",
  ),
  "pale_oak_wood": MinecraftMaterial(
    name: "Pale Oak Wood",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/pale_oak_wood.png",
  ),
  "pink_bundle": MinecraftMaterial(
    name: "Pink Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pink_bundle.png",
  ),
  "pink_harness": MinecraftMaterial(
    name: "Pink Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/pink_harness.png",
  ),
  "purple_bundle": MinecraftMaterial(
    name: "Purple Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/purple_bundle.png",
  ),
  "purple_harness": MinecraftMaterial(
    name: "Purple Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/purple_harness.png",
  ),
  "red_bundle": MinecraftMaterial(
    name: "Red Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/red_bundle.png",
  ),
  "red_harness": MinecraftMaterial(
    name: "Red Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/red_harness.png",
  ),
  "resin_block": MinecraftMaterial(
    name: "Block of Resin",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_block.png",
  ),
  "resin_brick": MinecraftMaterial(
    name: "Resin Brick",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick.png",
  ),
  "resin_brick_slab": MinecraftMaterial(
    name: "Resin Brick Slab",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick_slab.png",
  ),
  "resin_brick_stairs": MinecraftMaterial(
    name: "Resin Brick Stairs",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick_stairs.png",
  ),
  "resin_brick_wall": MinecraftMaterial(
    name: "Resin Brick Wall",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_brick_wall.png",
  ),
  "resin_bricks": MinecraftMaterial(
    name: "Resin Bricks",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_bricks.png",
  ),
  "resin_clump": MinecraftMaterial(
    name: "Resin Clump",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/resin_clump.png",
  ),
  "short_dry_grass": MinecraftMaterial(
    name: "Short Dry Grass",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/short_dry_grass.png",
  ),
  "short_grass": MinecraftMaterial(
    name: "Short Grass",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/short_grass.png",
  ),
  "tall_dry_grass": MinecraftMaterial(
    name: "Tall Dry Grass",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/tall_dry_grass.png",
  ),
  "waxed_copper_bulb": MinecraftMaterial(
    name: "Waxed Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_bulb.png",
  ),
  "waxed_copper_door": MinecraftMaterial(
    name: "Waxed Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_door.png",
  ),
  "waxed_copper_grate": MinecraftMaterial(
    name: "Waxed Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_grate.png",
  ),
  "waxed_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_copper_trapdoor.png",
  ),
  "waxed_exposed_copper_bulb": MinecraftMaterial(
    name: "Waxed Exposed Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_bulb.png",
  ),
  "waxed_exposed_copper_door": MinecraftMaterial(
    name: "Waxed Exposed Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_door.png",
  ),
  "waxed_exposed_copper_grate": MinecraftMaterial(
    name: "Waxed Exposed Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_grate.png",
  ),
  "waxed_exposed_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Exposed Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_trapdoor.png",
  ),
  "waxed_exposed_copper_lantern": MinecraftMaterial(
    name: "Waxed Exposed Copper Lantern",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_exposed_copper_lantern.png",
  ),
  "waxed_oxidized_copper_bulb": MinecraftMaterial(
    name: "Waxed Oxidized Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_bulb.png",
  ),
  "waxed_oxidized_copper_door": MinecraftMaterial(
    name: "Waxed Oxidized Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_door.png",
  ),
  "waxed_oxidized_copper_grate": MinecraftMaterial(
    name: "Waxed Oxidized Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_grate.png",
  ),
  "waxed_oxidized_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Oxidized Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_trapdoor.png",
  ),
  "waxed_oxidized_copper_lantern": MinecraftMaterial(
    name: "Waxed Oxidized Copper Lantern",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_oxidized_copper_lantern.png",
  ),
  "waxed_weathered_copper_bulb": MinecraftMaterial(
    name: "Waxed Weathered Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_bulb.png",
  ),
  "waxed_weathered_copper_door": MinecraftMaterial(
    name: "Waxed Weathered Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_door.png",
  ),
  "waxed_weathered_copper_grate": MinecraftMaterial(
    name: "Waxed Weathered Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_grate.png",
  ),
  "waxed_weathered_copper_trapdoor": MinecraftMaterial(
    name: "Waxed Weathered Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_trapdoor.png",
  ),
  "waxed_weathered_copper_lantern": MinecraftMaterial(
    name: "Waxed Weathered Copper Lantern",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/waxed_weathered_copper_lantern.png",
  ),
  "weathered_copper_bulb": MinecraftMaterial(
    name: "Weathered Copper Bulb",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_bulb.png",
  ),
  "weathered_copper_door": MinecraftMaterial(
    name: "Weathered Copper Door",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_door.png",
  ),
  "weathered_copper_grate": MinecraftMaterial(
    name: "Weathered Copper Grate",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_grate.png",
  ),
  "weathered_copper_trapdoor": MinecraftMaterial(
    name: "Weathered Copper Trapdoor",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_trapdoor.png",
  ),
  "weathered_copper_lantern": MinecraftMaterial(
    name: "Weathered Copper Lantern",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/weathered_copper_lantern.png",
  ),
  "white_bundle": MinecraftMaterial(
    name: "White Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/white_bundle.png",
  ),
  "white_harness": MinecraftMaterial(
    name: "White Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/white_harness.png",
  ),
  "wildflowers": MinecraftMaterial(
    name: "Wildflowers",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.block,
      MaterialProperty.item,
    ],
    icon: "assets/materials/wildflowers.png",
  ),
  "yellow_bundle": MinecraftMaterial(
    name: "Yellow Bundle",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/yellow_bundle.png",
  ),
  "yellow_harness": MinecraftMaterial(
    name: "Yellow Harness",
    since: McVersion.v1_21,
    properties: [
      MaterialProperty.item,
    ],
    icon: "assets/materials/yellow_harness.png",
  ),
};

@freezed
class MinecraftMaterial with _$MinecraftMaterial {
  const factory MinecraftMaterial({
    required String name,
    required List<MaterialProperty> properties,
    required String icon,
    McVersion? since,
  }) = _MinecraftMaterial;

  factory MinecraftMaterial.fromJson(Map<String, dynamic> json) =>
      _$MinecraftMaterialFromJson(json);
}
