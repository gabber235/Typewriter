package com.typewritermc.playtest.plugin;

import ca.spottedleaf.moonrise.patches.chunk_system.player.ChunkSystemServerPlayer;
import com.destroystokyo.paper.profile.PlayerProfile;
import com.destroystokyo.paper.profile.ProfileProperty;
import com.typewritermc.playtest.wire.Message.Kind;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import net.kyori.adventure.bossbar.BossBar;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer;
import net.kyori.adventure.util.TriState;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.resources.Identifier;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.stats.ServerStatsCounter;
import net.minecraft.stats.Stat;
import net.minecraft.stats.StatType;
import net.minecraft.world.entity.ai.attributes.AttributeSupplier;
import net.minecraft.world.entity.EntityTypes;
import net.minecraft.world.entity.ai.attributes.DefaultAttributes;
import net.minecraft.world.item.ItemCooldowns;
import org.bukkit.Bukkit;
import org.bukkit.Color;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.NamespacedKey;
import org.bukkit.Registry;
import org.bukkit.Statistic;
import org.bukkit.WeatherType;
import org.bukkit.WorldBorder;
import org.bukkit.advancement.Advancement;
import org.bukkit.advancement.AdvancementProgress;
import org.bukkit.attribute.Attribute;
import org.bukkit.attribute.AttributeInstance;
import org.bukkit.attribute.AttributeModifier;
import org.bukkit.boss.KeyedBossBar;
import org.bukkit.craftbukkit.attribute.CraftAttribute;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.ArmorStand;
import org.bukkit.entity.EntityType;
import org.bukkit.entity.Parrot;
import org.bukkit.entity.Player;
import org.bukkit.entity.Pose;
import org.bukkit.event.inventory.InventoryType;
import org.bukkit.inventory.ItemStack;
import org.bukkit.persistence.PersistentDataType;
import org.bukkit.potion.PotionEffect;
import org.bukkit.potion.PotionEffectType;
import org.bukkit.scoreboard.Criteria;
import org.bukkit.scoreboard.Objective;
import org.bukkit.scoreboard.Score;
import org.bukkit.scoreboard.Scoreboard;
import org.bukkit.scoreboard.Team;

/**
 * Each kind of vanilla and Paper state a player keeps, named as its {@link Kind}: how Paper wipes it to
 * what a player who never played has, and the mark and its check that the framework's own test kit uses
 * to prove the wipe. Paper wipes the kinds in this order, as some depend on others: the game mode decides
 * whether the player may fly, effects and attributes decide its maximum health. Main thread only.
 */
@SuppressWarnings("deprecation") // Paper deprecates the shoulder entity calls, the only way to reach that state.
enum PaperState {
    /** Closing the container also closes every other screen on the client, a sign editor among them. */
    OPEN_CONTAINER {
        @Override
        void wipe(Player player) {
            player.closeInventory();
        }

        @Override
        void mark(Player player) {
            player.openInventory(Bukkit.createInventory(null, InventoryType.CHEST, Component.text(MARK)));
        }

        @Override
        boolean marked(Player player) {
            return player.getOpenInventory().getTopInventory().getType() != InventoryType.CRAFTING;
        }
    },
    RIDING {
        @Override
        void wipe(Player player) {
            player.leaveVehicle();
            player.eject();
            player.setShoulderEntityLeft(null);
            player.setShoulderEntityRight(null);
        }

        @Override
        void mark(Player player) {
            Location at = player.getLocation();
            player.getWorld().spawn(at, ArmorStand.class).addPassenger(player);
            player.addPassenger(player.getWorld().spawn(at, ArmorStand.class));
            player.setShoulderEntityLeft(player.getWorld().spawn(at, Parrot.class));
        }

        @Override
        boolean marked(Player player) {
            return player.isInsideVehicle() || !player.getPassengers().isEmpty() || player.getShoulderEntityLeft() != null || player.getShoulderEntityRight() != null;
        }
    },
    GAME_MODE {
        @Override
        void wipe(Player player) {
            player.setGameMode(Bukkit.getDefaultGameMode());
        }

        @Override
        void mark(Player player) {
            player.setGameMode(Bukkit.getDefaultGameMode() == GameMode.ADVENTURE ? GameMode.SURVIVAL : GameMode.ADVENTURE);
        }

        @Override
        boolean marked(Player player) {
            return player.getGameMode() != Bukkit.getDefaultGameMode();
        }
    },
    /** After the game mode, which decides whether a new player may fly. */
    FLIGHT {
        @Override
        void wipe(Player player) {
            player.setAllowFlight(mayFly(player));
            player.setFlying(player.getGameMode() == GameMode.SPECTATOR);
            player.setFlyingFallDamage(TriState.NOT_SET);
        }

        @Override
        void mark(Player player) {
            player.setAllowFlight(true);
            player.setFlying(true);
            player.setFlyingFallDamage(TriState.TRUE);
        }

        @Override
        boolean marked(Player player) {
            return player.getAllowFlight() != mayFly(player)
                    || player.isFlying() != (player.getGameMode() == GameMode.SPECTATOR)
                    || player.hasFlyingFallDamage() != TriState.NOT_SET;
        }

        private static boolean mayFly(Player player) {
            return player.getGameMode() == GameMode.CREATIVE || player.getGameMode() == GameMode.SPECTATOR;
        }
    },
    SPEED {
        @Override
        void wipe(Player player) {
            player.setWalkSpeed(WALK_SPEED);
            player.setFlySpeed(FLY_SPEED);
        }

        @Override
        void mark(Player player) {
            player.setWalkSpeed(WALK_SPEED * 2);
            player.setFlySpeed(FLY_SPEED * 2);
        }

        @Override
        boolean marked(Player player) {
            return player.getWalkSpeed() != WALK_SPEED || player.getFlySpeed() != FLY_SPEED;
        }
    },
    /** Before the attributes, as an effect brings attribute modifiers of its own. */
    EFFECTS {
        @Override
        void wipe(Player player) {
            player.clearActivePotionEffects();
        }

        @Override
        void mark(Player player) {
            player.addPotionEffect(new PotionEffect(PotionEffectType.SPEED, MARK_TICKS, 0, true, false, false));
        }

        @Override
        boolean marked(Player player) {
            return !player.getActivePotionEffects().isEmpty();
        }
    },
    /**
     * Vanilla gives a creative player its reach modifiers again every tick, and a sprinting player its
     * speed modifier, all in the minecraft namespace; a mark is a base value or a modifier of any other.
     */
    ATTRIBUTES {
        @Override
        void wipe(Player player) {
            var attributes = handle(player).getAttributes();
            for (Attribute attribute : Registry.ATTRIBUTE) {
                AttributeInstance instance = player.getAttribute(attribute);
                if (instance == null) continue;
                for (AttributeModifier modifier : List.copyOf(instance.getModifiers())) instance.removeModifier(modifier);
                attributes.resetBaseValue(CraftAttribute.bukkitToMinecraftHolder(attribute));
            }
        }

        @Override
        void mark(Player player) {
            player.getAttribute(Attribute.LUCK).setBaseValue(MARK_LUCK);
            player.getAttribute(Attribute.ATTACK_DAMAGE).addModifier(new AttributeModifier(MARK_KEY, 1, AttributeModifier.Operation.ADD_NUMBER));
        }

        @Override
        boolean marked(Player player) {
            AttributeSupplier defaults = DefaultAttributes.getSupplier(EntityTypes.PLAYER);
            for (Attribute attribute : Registry.ATTRIBUTE) {
                AttributeInstance instance = player.getAttribute(attribute);
                if (instance == null) continue;
                var holder = CraftAttribute.bukkitToMinecraftHolder(attribute);
                if (!defaults.hasAttribute(holder) || instance.getBaseValue() != defaults.getBaseValue(holder)) return true;
                if (instance.getModifiers().stream().anyMatch(modifier -> !modifier.getKey().getNamespace().equals(NamespacedKey.MINECRAFT))) return true;
            }
            return false;
        }
    },
    /** After the effects and attributes, which decide the maximum health. */
    HEALTH {
        @Override
        void wipe(Player player) {
            player.setHealth(player.getAttribute(Attribute.MAX_HEALTH).getValue());
            // Setting a scale also turns scaling on, so scaling goes off after it.
            player.setHealthScale(HEALTH_SCALE);
            player.setHealthScaled(false);
        }

        @Override
        void mark(Player player) {
            player.setHealth(2);
            player.setHealthScale(HEALTH_SCALE * 2);
            player.setHealthScaled(true);
        }

        @Override
        boolean marked(Player player) {
            return player.getHealth() < player.getAttribute(Attribute.MAX_HEALTH).getValue() || player.isHealthScaled() || player.getHealthScale() != HEALTH_SCALE;
        }
    },
    /**
     * On the test Paper's peaceful difficulty vanilla fills saturation every tick, so saturation is no mark
     * there; the wipe still sets the saturation a new player has, for a Paper on any other difficulty.
     */
    FOOD {
        @Override
        void wipe(Player player) {
            player.setFoodLevel(FOOD_LEVEL);
            player.setSaturation(SATURATION);
            player.setExhaustion(0);
            player.setSaturatedRegenRate(SATURATED_REGEN_RATE);
            player.setUnsaturatedRegenRate(UNSATURATED_REGEN_RATE);
            player.setStarvationRate(STARVATION_RATE);
        }

        @Override
        void mark(Player player) {
            player.setFoodLevel(0);
            player.setSaturation(0);
            player.setExhaustion(3);
            player.setSaturatedRegenRate(SATURATED_REGEN_RATE * 2);
            player.setUnsaturatedRegenRate(UNSATURATED_REGEN_RATE * 2);
            player.setStarvationRate(STARVATION_RATE * 2);
        }

        @Override
        boolean marked(Player player) {
            return player.getFoodLevel() != FOOD_LEVEL
                    || player.getExhaustion() != 0
                    || player.getSaturatedRegenRate() != SATURATED_REGEN_RATE
                    || player.getUnsaturatedRegenRate() != UNSATURATED_REGEN_RATE
                    || player.getStarvationRate() != STARVATION_RATE;
        }
    },
    AIR {
        @Override
        void wipe(Player player) {
            player.setMaximumAir(handle(player).getDefaultMaxAirSupply());
            player.setRemainingAir(player.getMaximumAir());
        }

        @Override
        void mark(Player player) {
            player.setMaximumAir(handle(player).getDefaultMaxAirSupply() * 2);
            player.setRemainingAir(1);
        }

        @Override
        boolean marked(Player player) {
            return player.getMaximumAir() != handle(player).getDefaultMaxAirSupply() || player.getRemainingAir() < player.getMaximumAir();
        }
    },
    FIRE {
        @Override
        void wipe(Player player) {
            player.setFireTicks(0);
            player.setVisualFire(TriState.NOT_SET);
        }

        @Override
        void mark(Player player) {
            player.setFireTicks(MARK_TICKS);
            player.setVisualFire(TriState.TRUE);
        }

        @Override
        boolean marked(Player player) {
            return player.getFireTicks() > 0 || player.getVisualFire() != TriState.NOT_SET;
        }
    },
    FREEZE {
        @Override
        void wipe(Player player) {
            player.lockFreezeTicks(false);
            player.setFreezeTicks(0);
        }

        @Override
        void mark(Player player) {
            player.setFreezeTicks(player.getMaxFreezeTicks());
            player.lockFreezeTicks(true);
        }

        @Override
        boolean marked(Player player) {
            return player.getFreezeTicks() > 0 || player.isFreezeTickingLocked();
        }
    },
    COMBAT {
        @Override
        void wipe(Player player) {
            // Bukkit's Entity.setLastDamageCause is deprecated for removal and internal; the server's own player clears it.
            ((CraftPlayer) player).setLastDamageCause(null);
            player.setLastDamage(0);
            player.setKiller(null);
            player.setNoDamageTicks(0);
            player.setMaximumNoDamageTicks(IMMUNE_TICKS);
        }

        @Override
        void mark(Player player) {
            player.setLastDamage(3);
            player.setKiller(player);
            player.setNoDamageTicks(MARK_TICKS);
            player.setMaximumNoDamageTicks(IMMUNE_TICKS * 2);
        }

        @Override
        boolean marked(Player player) {
            return player.getLastDamageCause() != null
                    || player.getLastDamage() != 0
                    || player.getKiller() != null
                    || player.getNoDamageTicks() > 0
                    || player.getMaximumNoDamageTicks() != IMMUNE_TICKS;
        }
    },
    DEATH {
        @Override
        void wipe(Player player) {
            player.setLastDeathLocation(null);
            player.setDeathScreenScore(0);
        }

        @Override
        void mark(Player player) {
            player.setLastDeathLocation(player.getLocation());
            player.setDeathScreenScore(7);
        }

        @Override
        boolean marked(Player player) {
            return player.getLastDeathLocation() != null || player.getDeathScreenScore() != 0;
        }
    },
    SCOREBOARD {
        @Override
        void wipe(Player player) {
            Scoreboard main = Bukkit.getScoreboardManager().getMainScoreboard();
            for (Team team : main.getTeams()) team.removeEntry(player.getName());
            main.resetScores(player.getName());
            player.setScoreboard(main);
        }

        @Override
        void mark(Player player) {
            Scoreboard main = Bukkit.getScoreboardManager().getMainScoreboard();
            Team team = main.getTeam(MARK);
            (team == null ? main.registerNewTeam(MARK) : team).addEntry(player.getName());
            Objective objective = main.getObjective(MARK);
            if (objective == null) objective = main.registerNewObjective(MARK, Criteria.DUMMY, Component.text(MARK));
            objective.getScore(player.getName()).setScore(1);
        }

        @Override
        boolean marked(Player player) {
            Scoreboard main = Bukkit.getScoreboardManager().getMainScoreboard();
            boolean scored = main.getScores(player.getName()).stream().anyMatch(Score::isScoreSet);
            return main.getEntryTeam(player.getName()) != null || scored || player.getScoreboard() != main;
        }
    },
    ENDER_CHEST {
        @Override
        void wipe(Player player) {
            player.getEnderChest().clear();
        }

        @Override
        void mark(Player player) {
            player.getEnderChest().addItem(new ItemStack(Material.STICK));
        }

        @Override
        boolean marked(Player player) {
            return !player.getEnderChest().isEmpty();
        }
    },
    EXPERIENCE {
        @Override
        void wipe(Player player) {
            player.setLevel(0);
            player.setExp(0);
            player.setTotalExperience(0);
        }

        @Override
        void mark(Player player) {
            player.giveExpLevels(3);
        }

        @Override
        boolean marked(Player player) {
            return player.getLevel() > 0 || player.getExp() > 0 || player.getTotalExperience() > 0;
        }
    },
    PERSISTENT_DATA {
        @Override
        void wipe(Player player) {
            var data = player.getPersistentDataContainer();
            for (NamespacedKey key : List.copyOf(data.getKeys())) data.remove(key);
        }

        @Override
        void mark(Player player) {
            player.getPersistentDataContainer().set(MARK_KEY, PersistentDataType.STRING, MARK);
        }

        @Override
        boolean marked(Player player) {
            return !player.getPersistentDataContainer().isEmpty();
        }
    },
    PLAYER_TIME {
        @Override
        void wipe(Player player) {
            player.resetPlayerTime();
            player.resetPlayerWeather();
        }

        @Override
        void mark(Player player) {
            player.setPlayerTime(18_000, false);
            player.setPlayerWeather(WeatherType.DOWNFALL);
        }

        @Override
        boolean marked(Player player) {
            return !player.isPlayerTimeRelative() || player.getPlayerTimeOffset() != 0 || player.getPlayerWeather() != null;
        }
    },
    BOSS_BAR {
        @Override
        void wipe(Player player) {
            shown(player).forEach(player::hideBossBar);
            Bukkit.getBossBars().forEachRemaining(bar -> bar.removePlayer(player));
        }

        @Override
        void mark(Player player) {
            player.showBossBar(BossBar.bossBar(Component.text(MARK), 1f, BossBar.Color.RED, BossBar.Overlay.PROGRESS));
        }

        @Override
        boolean marked(Player player) {
            if (!shown(player).isEmpty()) return true;
            for (Iterator<KeyedBossBar> bars = Bukkit.getBossBars(); bars.hasNext(); ) {
                if (bars.next().getPlayers().contains(player)) return true;
            }
            return false;
        }

        /** The boss bars shown to the player, copied so that hiding one does not disturb the walk. */
        private static List<BossBar> shown(Player player) {
            var shown = new ArrayList<BossBar>();
            player.activeBossBars().forEach(shown::add);
            return shown;
        }
    },
    /**
     * Vanilla gives every player the crafting table recipe, through an advancement that unlocks it right
     * away, so a player who never played already holds a recipe and an advancement; their marks are a
     * recipe and an advancement no player gets on its own.
     */
    RECIPES {
        @Override
        void wipe(Player player) {
            player.undiscoverRecipes(player.getDiscoveredRecipes());
        }

        @Override
        void mark(Player player) {
            player.discoverRecipe(MARKED_RECIPE);
        }

        @Override
        boolean marked(Player player) {
            return player.hasDiscoveredRecipe(MARKED_RECIPE);
        }
    },
    ADVANCEMENTS {
        @Override
        void wipe(Player player) {
            for (Iterator<Advancement> all = Bukkit.advancementIterator(); all.hasNext(); ) {
                AdvancementProgress progress = player.getAdvancementProgress(all.next());
                for (String criterion : List.copyOf(progress.getAwardedCriteria())) progress.revokeCriteria(criterion);
            }
        }

        @Override
        void mark(Player player) {
            Advancement marked = markedAdvancement();
            AdvancementProgress progress = player.getAdvancementProgress(marked);
            for (String criterion : marked.getCriteria()) progress.awardCriteria(criterion);
        }

        @Override
        boolean marked(Player player) {
            return !player.getAdvancementProgress(markedAdvancement()).getAwardedCriteria().isEmpty();
        }

        private static Advancement markedAdvancement() {
            Advancement marked = Bukkit.getAdvancement(MARKED_ADVANCEMENT);
            if (marked == null) throw new IllegalStateException("this Paper has no " + MARKED_ADVANCEMENT + " advancement");
            return marked;
        }
    },
    /** Every player counts its playing time from its first tick, so the mark is a few counts no player gets standing still. */
    STATISTICS {
        @Override
        void wipe(Player player) {
            ServerPlayer handle = handle(player);
            ServerStatsCounter stats = handle.getStats();
            for (StatType<?> type : BuiltInRegistries.STAT_TYPE) {
                for (Stat<?> stat : type) {
                    if (stats.getValue(stat) != 0) stats.setValue(handle, stat, 0);
                }
            }
        }

        @Override
        void mark(Player player) {
            player.setStatistic(Statistic.ANIMALS_BRED, 1);
            player.setStatistic(Statistic.MINE_BLOCK, Material.STONE, 1);
            player.setStatistic(Statistic.CRAFT_ITEM, Material.STICK, 1);
            player.setStatistic(Statistic.KILL_ENTITY, EntityType.ZOMBIE, 1);
        }

        @Override
        boolean marked(Player player) {
            return player.getStatistic(Statistic.ANIMALS_BRED) != 0
                    || player.getStatistic(Statistic.MINE_BLOCK, Material.STONE) != 0
                    || player.getStatistic(Statistic.CRAFT_ITEM, Material.STICK) != 0
                    || player.getStatistic(Statistic.KILL_ENTITY, EntityType.ZOMBIE) != 0;
        }
    },
    HELD_SLOT {
        @Override
        void wipe(Player player) {
            player.getInventory().setHeldItemSlot(0);
        }

        @Override
        void mark(Player player) {
            player.getInventory().setHeldItemSlot(HELD_MARK);
        }

        @Override
        boolean marked(Player player) {
            return player.getInventory().getHeldItemSlot() != 0;
        }
    },
    /** One respawn point holds a bed or a respawn anchor alike, so clearing it clears both. */
    SPAWN_POINT {
        @Override
        void wipe(Player player) {
            player.setRespawnLocation(null);
        }

        @Override
        void mark(Player player) {
            player.setRespawnLocation(player.getLocation(), true);
        }

        @Override
        boolean marked(Player player) {
            return player.getPotentialRespawnLocation() != null;
        }
    },
    /**
     * A player who never played has no compass target: its compass points at the world spawn Paper sent
     * when it joined. Paper offers no call that clears a target, so the wipe points the compass back at
     * the world spawn and then clears the field Paper keeps the target in.
     */
    COMPASS {
        @Override
        void wipe(Player player) {
            if (player.getCompassTarget() == null) return;
            player.setCompassTarget(Bukkit.getWorlds().getFirst().getSpawnLocation());
            handle(player).compassTarget = null;
        }

        @Override
        void mark(Player player) {
            player.setCompassTarget(player.getLocation().add(MARK_DISTANCE, 0, 0));
        }

        @Override
        boolean marked(Player player) {
            return player.getCompassTarget() != null;
        }
    },
    /**
     * Item cooldowns are kept per cooldown group, which Paper cannot list; the wipe clears each item's
     * own group. A custom group comes from items a plugin made, so that plugin clears it on the wipe.
     */
    COOLDOWNS {
        @Override
        void wipe(Player player) {
            ItemCooldowns cooldowns = handle(player).getCooldowns();
            for (Identifier item : BuiltInRegistries.ITEM.keySet()) cooldowns.removeCooldown(item);
            player.setPortalCooldown(0);
            player.setExpCooldown(0);
        }

        @Override
        void mark(Player player) {
            player.setCooldown(Material.ENDER_PEARL, MARK_TICKS);
            player.setPortalCooldown(MARK_TICKS);
            player.setExpCooldown(MARK_TICKS);
        }

        @Override
        boolean marked(Player player) {
            return player.hasCooldown(Material.ENDER_PEARL) || player.getPortalCooldown() > 0 || player.getExpCooldown() > 0;
        }
    },
    ENTITY_FLAGS {
        @Override
        void wipe(Player player) {
            player.setInvulnerable(false);
            player.setSilent(false);
            player.setGravity(true);
            player.setCollidable(true);
            player.setCanPickupItems(true);
            player.setNoPhysics(false);
            player.setSleepingIgnored(false);
            player.setAffectsSpawning(true);
            player.setSneaking(false);
            player.setSprinting(false);
            if (player.hasFixedPose()) player.setPose(Pose.STANDING, false);
        }

        @Override
        void mark(Player player) {
            player.setInvulnerable(true);
            player.setSilent(true);
            player.setGravity(false);
            player.setCollidable(false);
            player.setCanPickupItems(false);
            player.setNoPhysics(true);
            player.setSleepingIgnored(true);
            player.setAffectsSpawning(false);
            player.setSneaking(true);
            player.setSprinting(true);
            player.setPose(Pose.SWIMMING, true);
        }

        @Override
        boolean marked(Player player) {
            return player.isInvulnerable()
                    || player.isSilent()
                    || !player.hasGravity()
                    || !player.isCollidable()
                    || !player.getCanPickupItems()
                    || player.hasNoPhysics()
                    || player.isSleepingIgnored()
                    || !player.getAffectsSpawning()
                    || player.isSneaking()
                    || player.isSprinting()
                    || player.hasFixedPose();
        }
    },
    /** A player who joins offline carries no profile properties, so any property is a mark. */
    APPEARANCE {
        @Override
        void wipe(Player player) {
            player.displayName(null);
            player.playerListName(null);
            player.setPlayerListOrder(0);
            player.setPlayerListHeaderFooter((String) null, null);
            player.setGlowing(false);
            player.setInvisible(false);
            player.setArrowsInBody(0, false);
            player.setBeeStingersInBody(0);
            player.setWaypointColor(null);
            if (!player.getPlayerProfile().getProperties().isEmpty()) {
                // Paper completes a new profile from its profile cache, which can hold the old properties.
                PlayerProfile fresh = Bukkit.createProfileExact(player.getUniqueId(), player.getName());
                fresh.clearProperties();
                player.setPlayerProfile(fresh);
            }
        }

        @Override
        void mark(Player player) {
            player.displayName(Component.text(MARK));
            player.playerListName(Component.text(MARK));
            player.setPlayerListOrder(1);
            player.setPlayerListHeaderFooter(MARK, MARK);
            player.setGlowing(true);
            player.setInvisible(true);
            player.setArrowsInBody(3, false);
            player.setBeeStingersInBody(2);
            player.setWaypointColor(Color.RED);
            PlayerProfile profile = Bukkit.createProfileExact(player.getUniqueId(), player.getName());
            profile.setProperty(new ProfileProperty(MARK, MARK));
            player.setPlayerProfile(profile);
        }

        @Override
        boolean marked(Player player) {
            return !plain(player.displayName()).equals(player.getName())
                    || !plain(player.playerListName()).equals(player.getName())
                    || player.getPlayerListOrder() != 0
                    || player.playerListHeader() != null
                    || player.playerListFooter() != null
                    || player.isGlowing()
                    || player.isInvisible()
                    || player.getArrowsInBody() > 0
                    || player.getBeeStingersInBody() > 0
                    || player.getWaypointColor() != null
                    || !player.getPlayerProfile().getProperties().isEmpty();
        }

        private static String plain(Component text) {
            return PlainTextComponentSerializer.plainText().serialize(text);
        }
    },
    TAGS {
        @Override
        void wipe(Player player) {
            for (String tag : List.copyOf(player.getScoreboardTags())) player.removeScoreboardTag(tag);
        }

        @Override
        void mark(Player player) {
            player.addScoreboardTag(MARK);
        }

        @Override
        boolean marked(Player player) {
            return !player.getScoreboardTags().isEmpty();
        }
    },
    WORLD_BORDER {
        @Override
        void wipe(Player player) {
            player.setWorldBorder(null);
        }

        @Override
        void mark(Player player) {
            WorldBorder border = Bukkit.createWorldBorder();
            border.setCenter(player.getLocation());
            border.setSize(MARK_DISTANCE * 10);
            player.setWorldBorder(border);
        }

        @Override
        boolean marked(Player player) {
            return player.getWorldBorder() != null;
        }
    },
    /** Paper keeps -1 for a distance the player takes from its world; the mark sets the distances the player already has. */
    VIEW_DISTANCE {
        @Override
        void wipe(Player player) {
            player.setViewDistance(-1);
            player.setSendViewDistance(-1);
            player.setSimulationDistance(-1);
        }

        @Override
        void mark(Player player) {
            player.setViewDistance(player.getViewDistance());
            player.setSendViewDistance(player.getSendViewDistance());
            player.setSimulationDistance(player.getSimulationDistance());
        }

        @Override
        boolean marked(Player player) {
            var distances = ((ChunkSystemServerPlayer) handle(player)).moonrise$getViewDistanceHolder().getViewDistances();
            return distances.loadViewDistance() != -1 || distances.sendViewDistance() != -1 || distances.tickViewDistance() != -1;
        }
    },
    /** The time since the last warning counts up every tick, so only the level and the cooldown are marks. */
    WARDEN {
        @Override
        void wipe(Player player) {
            player.setWardenWarningLevel(0);
            player.setWardenWarningCooldown(0);
            player.setWardenTimeSinceLastWarning(0);
        }

        @Override
        void mark(Player player) {
            player.setWardenWarningLevel(3);
            player.setWardenWarningCooldown(MARK_TICKS);
        }

        @Override
        boolean marked(Player player) {
            return player.getWardenWarningLevel() > 0 || player.getWardenWarningCooldown() > 0;
        }
    },
    CREDITS {
        @Override
        void wipe(Player player) {
            player.setHasSeenWinScreen(false);
        }

        @Override
        void mark(Player player) {
            player.setHasSeenWinScreen(true);
        }

        @Override
        boolean marked(Player player) {
            return player.hasSeenWinScreen();
        }
    },
    /** A new player gets a random seed, so the wipe draws a new one and the mark is one fixed seed. */
    ENCHANTMENT_SEED {
        @Override
        void wipe(Player player) {
            player.setEnchantmentSeed(ThreadLocalRandom.current().nextInt());
        }

        @Override
        void mark(Player player) {
            player.setEnchantmentSeed(MARK_SEED);
        }

        @Override
        boolean marked(Player player) {
            return player.getEnchantmentSeed() == MARK_SEED;
        }
    };

    private static final String MARK = "playtest-mark";
    private static final NamespacedKey MARK_KEY = new NamespacedKey("playtest", "mark");
    private static final int MARK_TICKS = 20 * 600;
    private static final int MARK_DISTANCE = 100;
    private static final int MARK_SEED = 0x7e57;
    private static final double MARK_LUCK = 3;
    private static final int HELD_MARK = 5;
    private static final NamespacedKey MARKED_RECIPE = NamespacedKey.minecraft("oak_planks");
    private static final NamespacedKey MARKED_ADVANCEMENT = NamespacedKey.minecraft("story/root");

    // What a player who never played has, as vanilla and Paper set it.
    private static final float WALK_SPEED = 0.2f;
    private static final float FLY_SPEED = 0.1f;
    private static final double HEALTH_SCALE = 20;
    private static final int FOOD_LEVEL = 20;
    private static final float SATURATION = 5;
    private static final int SATURATED_REGEN_RATE = 10;
    private static final int UNSATURATED_REGEN_RATE = 80;
    private static final int STARVATION_RATE = 80;
    private static final int IMMUNE_TICKS = 20;

    private static final Map<Kind, PaperState> BY_KIND = new EnumMap<>(Kind.class);

    static {
        for (PaperState state : values()) BY_KIND.put(Kind.valueOf(state.name()), state);
    }

    /** Sets this kind of the player's state to what a player who never played has. */
    abstract void wipe(Player player);

    /** Leaves a mark of this kind on the player, as an earlier attempt could. */
    abstract void mark(Player player);

    /** Whether the player carries a mark of this kind, whoever left it. */
    abstract boolean marked(Player player);

    /** The state of [kind], or null for a kind a plugin keeps. */
    static PaperState of(Kind kind) {
        return BY_KIND.get(kind);
    }

    private static ServerPlayer handle(Player player) {
        return ((CraftPlayer) player).getHandle();
    }
}
