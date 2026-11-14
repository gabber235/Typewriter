package com.typewritermc.playtest.plugin;

import com.typewritermc.playtest.wire.Message.Kind;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import net.kyori.adventure.bossbar.BossBar;
import net.kyori.adventure.text.Component;
import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Material;
import org.bukkit.NamespacedKey;
import org.bukkit.WeatherType;
import org.bukkit.advancement.Advancement;
import org.bukkit.advancement.AdvancementProgress;
import org.bukkit.boss.KeyedBossBar;
import org.bukkit.entity.Player;
import org.bukkit.inventory.ItemStack;
import org.bukkit.persistence.PersistentDataType;
import org.bukkit.plugin.Plugin;
import org.bukkit.potion.PotionEffect;
import org.bukkit.potion.PotionEffectType;
import org.bukkit.scoreboard.Criteria;
import org.bukkit.scoreboard.Objective;
import org.bukkit.scoreboard.Score;
import org.bukkit.scoreboard.Scoreboard;
import org.bukkit.scoreboard.Team;

/**
 * The vanilla and Paper state of a player, which Paper wipes before every attempt so each attempt finds
 * its players as players who never played: the inventory and every {@link #KINDS kind} Paper itself
 * keeps. State a plugin keeps is that plugin's to reset on the {@link PlayerWipeEvent}. Marks and their
 * check serve the framework's own test kit, which proves the wipe clears each kind. Main thread only.
 */
final class Wipe {
    /** The kinds Paper keeps, which this wipe clears. */
    static final Set<Kind> KINDS =
            EnumSet.of(
                    Kind.SCOREBOARD,
                    Kind.ENDER_CHEST,
                    Kind.EFFECTS,
                    Kind.EXPERIENCE,
                    Kind.PERSISTENT_DATA,
                    Kind.PLAYER_TIME,
                    Kind.BOSS_BAR,
                    Kind.RECIPES,
                    Kind.ADVANCEMENTS,
                    Kind.GAME_MODE,
                    Kind.HELD_SLOT);

    private static final String MARK = "playtest-mark";
    private static final int HELD_MARK = 5;
    private static final int EFFECT_TICKS = 20 * 600;
    /**
     * Vanilla gives every player the crafting table recipe, through an advancement that unlocks it right
     * away, so a player who never played already holds a recipe and an advancement. Their marks are these
     * two, which no player gets on its own.
     */
    private static final NamespacedKey MARKED_RECIPE = NamespacedKey.minecraft("oak_planks");

    private static final NamespacedKey MARKED_ADVANCEMENT = NamespacedKey.minecraft("story/root");

    private final NamespacedKey markKey;

    Wipe(Plugin plugin) {
        this.markKey = new NamespacedKey(plugin, MARK);
    }

    /** Clears the player's inventory and every kind Paper keeps. */
    void wipe(Player player) {
        player.closeInventory();
        player.getInventory().clear();
        player.setItemOnCursor(null);
        Scoreboard main = Bukkit.getScoreboardManager().getMainScoreboard();
        for (Team team : main.getTeams()) team.removeEntry(player.getName());
        main.resetScores(player.getName());
        player.setScoreboard(main);
        player.getEnderChest().clear();
        player.clearActivePotionEffects();
        player.setLevel(0);
        player.setExp(0);
        player.setTotalExperience(0);
        var data = player.getPersistentDataContainer();
        for (NamespacedKey key : List.copyOf(data.getKeys())) data.remove(key);
        player.resetPlayerTime();
        player.resetPlayerWeather();
        shown(player).forEach(player::hideBossBar);
        Bukkit.getBossBars().forEachRemaining(bar -> bar.removePlayer(player));
        player.undiscoverRecipes(player.getDiscoveredRecipes());
        for (Iterator<Advancement> all = Bukkit.advancementIterator(); all.hasNext(); ) {
            AdvancementProgress progress = player.getAdvancementProgress(all.next());
            for (String criterion : List.copyOf(progress.getAwardedCriteria())) progress.revokeCriteria(criterion);
        }
        player.setGameMode(Bukkit.getDefaultGameMode());
        player.getInventory().setHeldItemSlot(0);
    }

    /** Leaves a mark of [kind] on the player, as an earlier attempt could. */
    void mark(Player player, Kind kind) {
        switch (kind) {
            case SCOREBOARD -> {
                Scoreboard main = Bukkit.getScoreboardManager().getMainScoreboard();
                Team team = main.getTeam(MARK);
                (team == null ? main.registerNewTeam(MARK) : team).addEntry(player.getName());
                Objective objective = main.getObjective(MARK);
                if (objective == null) objective = main.registerNewObjective(MARK, Criteria.DUMMY, Component.text(MARK));
                objective.getScore(player.getName()).setScore(1);
            }
            case ENDER_CHEST -> player.getEnderChest().addItem(new ItemStack(Material.STICK));
            case EFFECTS -> player.addPotionEffect(new PotionEffect(PotionEffectType.SPEED, EFFECT_TICKS, 0, true, false, false));
            case EXPERIENCE -> player.giveExpLevels(3);
            case PERSISTENT_DATA -> player.getPersistentDataContainer().set(markKey, PersistentDataType.STRING, MARK);
            case PLAYER_TIME -> {
                player.setPlayerTime(18_000, false);
                player.setPlayerWeather(WeatherType.DOWNFALL);
            }
            case BOSS_BAR -> player.showBossBar(BossBar.bossBar(Component.text(MARK), 1f, BossBar.Color.RED, BossBar.Overlay.PROGRESS));
            case RECIPES -> player.discoverRecipe(MARKED_RECIPE);
            case ADVANCEMENTS -> {
                Advancement marked = markedAdvancement();
                AdvancementProgress progress = player.getAdvancementProgress(marked);
                for (String criterion : marked.getCriteria()) progress.awardCriteria(criterion);
            }
            case GAME_MODE -> player.setGameMode(Bukkit.getDefaultGameMode() == GameMode.ADVENTURE ? GameMode.SURVIVAL : GameMode.ADVENTURE);
            case HELD_SLOT -> player.getInventory().setHeldItemSlot(HELD_MARK);
            default -> throw new IllegalArgumentException(kind + " is a kind a plugin keeps, not Paper");
        }
    }

    /**
     * Whether the player carries a mark of [kind]: anything of that kind a player who never played lacks,
     * or for recipes and advancements, which every player holds some of, the mark itself.
     */
    boolean marked(Player player, Kind kind) {
        return switch (kind) {
            case SCOREBOARD -> {
                Scoreboard main = Bukkit.getScoreboardManager().getMainScoreboard();
                boolean scored = main.getScores(player.getName()).stream().anyMatch(Score::isScoreSet);
                yield main.getEntryTeam(player.getName()) != null || scored || player.getScoreboard() != main;
            }
            case ENDER_CHEST -> !player.getEnderChest().isEmpty();
            case EFFECTS -> !player.getActivePotionEffects().isEmpty();
            case EXPERIENCE -> player.getLevel() > 0 || player.getExp() > 0 || player.getTotalExperience() > 0;
            case PERSISTENT_DATA -> !player.getPersistentDataContainer().isEmpty();
            case PLAYER_TIME -> !player.isPlayerTimeRelative() || player.getPlayerTimeOffset() != 0 || player.getPlayerWeather() != null;
            case BOSS_BAR -> !shown(player).isEmpty() || keyedBarShown(player);
            case RECIPES -> player.hasDiscoveredRecipe(MARKED_RECIPE);
            case ADVANCEMENTS -> !player.getAdvancementProgress(markedAdvancement()).getAwardedCriteria().isEmpty();
            case GAME_MODE -> player.getGameMode() != Bukkit.getDefaultGameMode();
            case HELD_SLOT -> player.getInventory().getHeldItemSlot() != 0;
            default -> throw new IllegalArgumentException(kind + " is a kind a plugin keeps, not Paper");
        };
    }

    private static boolean keyedBarShown(Player player) {
        for (Iterator<KeyedBossBar> bars = Bukkit.getBossBars(); bars.hasNext(); ) {
            if (bars.next().getPlayers().contains(player)) return true;
        }
        return false;
    }

    private static Advancement markedAdvancement() {
        Advancement marked = Bukkit.getAdvancement(MARKED_ADVANCEMENT);
        if (marked == null) throw new IllegalStateException("this Paper has no " + MARKED_ADVANCEMENT + " advancement");
        return marked;
    }

    /** The boss bars shown to the player, copied so that hiding one does not disturb the walk. */
    private static List<BossBar> shown(Player player) {
        var shown = new ArrayList<BossBar>();
        player.activeBossBars().forEach(shown::add);
        return shown;
    }
}
