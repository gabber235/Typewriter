package com.typewritermc.playtest.plugin;

import com.destroystokyo.paper.event.player.PlayerUseUnknownEntityEvent;
import build.skir.internal.MustNameArguments;
import com.typewritermc.playtest.wire.Payload;
import io.papermc.paper.adventure.PaperAdventure;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.BiConsumer;
import net.kyori.adventure.text.Component;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.protocol.common.ClientboundCustomPayloadPacket;
import net.minecraft.network.protocol.common.custom.DiscardedPayload;
import net.minecraft.network.protocol.game.ClientboundAddEntityPacket;
import net.minecraft.network.protocol.game.ClientboundRemoveEntitiesPacket;
import net.minecraft.network.protocol.game.ClientboundSetEntityDataPacket;
import net.minecraft.resources.Identifier;
import net.minecraft.world.entity.EntitySpawnReason;
import net.minecraft.world.phys.Vec3;
import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.NamespacedKey;
import org.bukkit.Registry;
import org.bukkit.World;
import org.bukkit.block.data.BlockData;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.craftbukkit.CraftServer;
import org.bukkit.craftbukkit.CraftWorld;
import org.bukkit.craftbukkit.entity.CraftEntity;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Entity;
import org.bukkit.entity.EntityType;
import org.bukkit.entity.LivingEntity;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.block.BlockBreakEvent;
import org.bukkit.event.entity.EntityDamageByEntityEvent;
import org.bukkit.event.player.PlayerInteractEntityEvent;
import org.bukkit.inventory.ItemStack;
import org.bukkit.plugin.Plugin;
import org.bukkit.scoreboard.Criteria;
import org.bukkit.scoreboard.DisplaySlot;
import org.bukkit.scoreboard.Objective;
import org.bukkit.scoreboard.Scoreboard;
import org.bukkit.util.Vector;
import org.jspecify.annotations.Nullable;
import skirout.harness.v1.wire.BlockPos;
import skirout.harness.v1.wire.PlayerAction;
import skirout.harness.v1.wire.ProbeAction;
import skirout.harness.v1.wire.StateKind;
import skirout.harness.v1.wire.Watch;
import skirout.harness.v1.wire.WorldAction;

/**
 * The arrangements a requirement asks Paper for. Main thread only. Each runs at once and returns null,
 * or returns why it could not. What a probe gives a player (a command, an entity only its client knows)
 * is that player's alone, and a claim takes it away again; what it places in the world stays in the
 * attempt's region, which no later attempt uses.
 */
final class Probes implements Listener {
    private static final int MAX_FILL = 4_096;
    private static final Identifier WATCH = Identifier.parse(Payload.WATCH_CHANNEL);

    /** How a probe entity answers a player: the name tag it shows once hit or used. */
    private record Reactions(@Nullable String onHit, @Nullable String onClick) {}

    /**
     * A packet only entity: the client that knows it, how it reacts, and a detached server entity of its
     * type, never added to a world, that gives it a network id and builds the metadata the client expects.
     */
    private record PacketEntity(UUID viewer, net.minecraft.world.entity.Entity detached, Reactions reactions) {}

    private final Map<UUID, Reactions> spawned = new HashMap<>();
    private final Map<Integer, PacketEntity> packetEntities = new HashMap<>();
    private final Set<Location> unbreakable = new HashSet<>();
    private final Map<String, SuggestingCommand> commands = new HashMap<>();
    private final Plugin plugin;
    private final BiConsumer<Player, StateKind> mark;

    /** [mark] leaves a mark of a kind of state on a player, for the framework's own test kit. */
    Probes(Plugin plugin, BiConsumer<Player, StateKind> mark) {
        this.plugin = plugin;
        this.mark = mark;
    }

    /**
     * Runs [action]: an action on a player for each of [players], an action on the world once, in their
     * world. Null when it ran, else why not.
     */
    @Nullable String run(List<Player> players, ProbeAction action) {
        watch(players, action);
        return switch (action) {
            case ProbeAction.OnWorldWrapper world -> run(players.getFirst().getWorld(), world.getValue());
            case ProbeAction.OnPlayerWrapper each -> {
                for (Player player : players) {
                    String failure = run(player, each.getValue());
                    if (failure != null) yield failure;
                }
                yield null;
            }
            default -> "a probe action this Paper does not know: " + action;
        };
    }

    private @Nullable String run(World world, WorldAction action) {
        return switch (action) {
            case WorldAction.FillWrapper fill -> fill(world, fill.getValue().getFrom(), fill.getValue().getTo(), fill.getValue().getBlock());
            case WorldAction.BlockWrapper block -> fill(world, block.getValue().getAt(), block.getValue().getAt(), block.getValue().getBlock());
            case WorldAction.SpawnWrapper spawn -> spawn(world, spawn.getValue());
            case WorldAction.CancelBreakingWrapper cancel -> {
                unbreakable.add(location(world, cancel.getValue().getAt()));
                yield null;
            }
            default -> "a world action this Paper does not know: " + action;
        };
    }

    private @Nullable String run(Player player, PlayerAction action) {
        return switch (action) {
            case PlayerAction.ChatWrapper chat -> {
                player.sendMessage(Component.text(chat.getValue().getText()));
                yield null;
            }
            case PlayerAction.GameModeWrapper mode -> gameMode(player, mode.getValue());
            case PlayerAction.TeleportWrapper wrapper -> {
                var teleport = wrapper.getValue();
                player.setVelocity(new Vector());
                player.setFallDistance(0);
                player.teleport(new Location(player.getWorld(), teleport.getX(), teleport.getY(), teleport.getZ(), teleport.getYaw(), teleport.getPitch()));
                yield null;
            }
            case PlayerAction.GiveWrapper give -> give(player, give.getValue());
            case PlayerAction.SelectSlotWrapper select -> {
                int slot = select.getValue().getSlot();
                if (slot < 0 || slot > 8) yield "hotbar slot " + slot + " is not 0 to 8";
                player.getInventory().setHeldItemSlot(slot);
                yield null;
            }
            case PlayerAction.PacketEntityWrapper entity -> packetEntity(player, entity.getValue());
            case PlayerAction.CommandWrapper command -> command(player, command.getValue());
            case PlayerAction.MarkWrapper marked -> {
                mark.accept(player, marked.getValue().getKind());
                yield null;
            }
            case PlayerAction.WorkWrapper work -> {
                work(player, work.getValue());
                yield null;
            }
            case PlayerAction.SidebarWrapper sidebar -> sidebar(player, sidebar.getValue());
            case PlayerAction.TimeWrapper time -> {
                player.setPlayerTime(time.getValue().getTime(), false);
                yield null;
            }
            case PlayerAction.SAVE save -> {
                player.saveData();
                yield null;
            }
            default -> "a player action this Paper does not know: " + action;
        };
    }

    /**
     * Each of [players] watches what [action] puts in front of it. Paper sends the watch on the player's
     * own connection ahead of the packets that show the block or entity, so the client handles the watch
     * first and records them from the tick those packets arrive in.
     */
    private static void watch(List<Player> players, ProbeAction action) {
        Watch watch = watchOf(action);
        if (watch != null) players.forEach(player -> watch(player, watch));
    }

    /** What [action] puts in front of its players: a block or an entity, or nothing to watch. */
    private static @Nullable Watch watchOf(ProbeAction action) {
        if (action instanceof ProbeAction.OnWorldWrapper world) {
            if (world.getValue() instanceof WorldAction.BlockWrapper block) return watch(List.of(block.getValue().getAt()), List.of());
            if (world.getValue() instanceof WorldAction.SpawnWrapper spawn) return watch(List.of(), List.of(spawn.getValue().getUuid()));
        }
        if (action instanceof ProbeAction.OnPlayerWrapper each && each.getValue() instanceof PlayerAction.PacketEntityWrapper entity) {
            return watch(List.of(), List.of(entity.getValue().getUuid()));
        }
        return null;
    }

    private static Watch watch(List<BlockPos> blocks, List<String> entities) {
        return new Watch(MustNameArguments.INSTANCE, blocks, entities, null);
    }

    /**
     * Sends [player]'s client [watch] as a raw payload, since Bukkit's plugin
     * messages drop channels the client never announced.
     */
    private static void watch(Player player, Watch watch) {
        send(player, new ClientboundCustomPayloadPacket(new DiscardedPayload(WATCH, Payload.body(watch))));
    }

    /**
     * Gives the player a scoreboard of its own whose sidebar shows the lines top to bottom: each line
     * scores one more than the line below it. The wipe hands the player the main scoreboard again.
     */
    private static @Nullable String sidebar(Player player, PlayerAction.Sidebar sidebar) {
        if (new HashSet<>(sidebar.getLines()).size() != sidebar.getLines().size()) return "a sidebar shows each line once: " + sidebar.getLines();
        Scoreboard board = Bukkit.getScoreboardManager().getNewScoreboard();
        Objective objective = board.registerNewObjective("playtest_sidebar", Criteria.DUMMY, Component.text(sidebar.getTitle()));
        objective.setDisplaySlot(DisplaySlot.SIDEBAR);
        for (int index = 0; index < sidebar.getLines().size(); index++) {
            objective.getScore(sidebar.getLines().get(index)).setScore(sidebar.getLines().size() - index);
        }
        player.setScoreboard(board);
        return null;
    }

    /**
     * Takes from [players] what earlier probes gave them alone: every probe command and every entity only
     * their clients know.
     */
    void forget(List<Player> players) {
        for (Player player : players) {
            for (SuggestingCommand command : commands.values()) command.answers.remove(player.getUniqueId());
            var known = packetEntities.entrySet().stream().filter(entry -> entry.getValue().viewer().equals(player.getUniqueId())).map(Map.Entry::getKey).toList();
            if (!known.isEmpty()) send(player, new ClientboundRemoveEntitiesPacket(known.stream().mapToInt(Integer::intValue).toArray()));
            known.forEach(packetEntities::remove);
            player.updateCommands();
        }
    }

    /**
     * Runs the work on Bukkit's async scheduler as a plugin would, counted from the moment it is handed
     * over. An interrupt would cancel it before its chat line; nothing here interrupts it.
     */
    private void work(Player player, PlayerAction.Work work) {
        Bukkit.getScheduler().runTaskAsynchronously(plugin, PlayerWork.task(player, work.getName(), () -> {
            try {
                Thread.sleep(work.getMillis());
            } catch (InterruptedException cancelled) {
                Thread.currentThread().interrupt();
                return;
            }
            player.sendMessage(Component.text(work.getChat()));
        }));
    }

    private static @Nullable String gameMode(Player player, skirout.harness.v1.wire.GameMode mode) {
        GameMode bukkit = switch (mode.getKind()) {
            case SURVIVAL_CONST -> GameMode.SURVIVAL;
            case CREATIVE_CONST -> GameMode.CREATIVE;
            case ADVENTURE_CONST -> GameMode.ADVENTURE;
            case SPECTATOR_CONST -> GameMode.SPECTATOR;
            case UNKNOWN -> null;
        };
        if (bukkit == null) return "game mode " + mode + " is none this plugin knows";
        player.setGameMode(bukkit);
        return null;
    }

    private static @Nullable String give(Player player, PlayerAction.Give give) {
        Material material = Material.matchMaterial(give.getItem());
        if (material == null || !material.isItem()) return "no item " + give.getItem();
        if (give.getSlot() < 0 || give.getSlot() > 40) return "inventory slot " + give.getSlot() + " is not 0 to 40";
        player.getInventory().setItem(give.getSlot(), material.isAir() ? null : new ItemStack(material, give.getCount()));
        return null;
    }

    private static @Nullable String fill(World world, BlockPos from, BlockPos to, String block) {
        BlockData data;
        try {
            data = Bukkit.createBlockData(block);
        } catch (IllegalArgumentException unknown) {
            return "no block state " + block;
        }
        long count = (long) (Math.abs(to.getX() - from.getX()) + 1) * (Math.abs(to.getY() - from.getY()) + 1) * (Math.abs(to.getZ() - from.getZ()) + 1);
        if (count > MAX_FILL) return "a fill of " + count + " blocks is over the limit of " + MAX_FILL;
        for (int x = Math.min(from.getX(), to.getX()); x <= Math.max(from.getX(), to.getX()); x++) {
            for (int y = Math.min(from.getY(), to.getY()); y <= Math.max(from.getY(), to.getY()); y++) {
                for (int z = Math.min(from.getZ(), to.getZ()); z <= Math.max(from.getZ(), to.getZ()); z++) {
                    world.getBlockAt(x, y, z).setBlockData(data, false);
                }
            }
        }
        return null;
    }

    private @Nullable String spawn(World world, WorldAction.Spawn spawn) {
        EntityType type = Registry.ENTITY_TYPE.get(NamespacedKey.fromString(spawn.getEntityType()));
        if (type == null || !type.isSpawnable() || type.getEntityClass() == null) return "no entity type " + spawn.getEntityType();
        var at = new Location(world, spawn.getX(), spawn.getY(), spawn.getZ(), spawn.getYaw(), 0);
        world.spawn(at, type.getEntityClass(), entity -> {
            ((CraftEntity) entity).getHandle().setUUID(UUID.fromString(spawn.getUuid()));
            entity.setSilent(true);
            entity.setPersistent(true);
            entity.setInvisible(spawn.getInvisible());
            if (entity instanceof LivingEntity living) {
                living.setAI(false);
                living.setRemoveWhenFarAway(false);
            }
        });
        spawned.put(UUID.fromString(spawn.getUuid()), new Reactions(spawn.getOnHit(), spawn.getOnClick()));
        return null;
    }

    private @Nullable String packetEntity(Player viewer, PlayerAction.PacketEntity spawn) {
        var key = Identifier.tryParse(spawn.getEntityType());
        var type = key == null ? null : BuiltInRegistries.ENTITY_TYPE.getOptional(key).orElse(null);
        if (type == null) return "no entity type " + spawn.getEntityType();
        var detached = type.create(((CraftWorld) viewer.getWorld()).getHandle(), EntitySpawnReason.COMMAND);
        if (detached == null) return "entity type " + spawn.getEntityType() + " cannot be created";
        int id = detached.getId();
        send(viewer, new ClientboundAddEntityPacket(id, UUID.fromString(spawn.getUuid()), spawn.getX(), spawn.getY(), spawn.getZ(), 0, spawn.getYaw(), type, 0, Vec3.ZERO, spawn.getYaw()));
        packetEntities.put(id, new PacketEntity(viewer.getUniqueId(), detached, new Reactions(spawn.getOnHit(), spawn.getOnClick())));
        return null;
    }

    /** [player] may run `/name`, which suggests and answers as [probe] says, for it alone. */
    private @Nullable String command(Player player, PlayerAction.Command probe) {
        SuggestingCommand command = commands.get(probe.getName());
        if (command == null) {
            command = new SuggestingCommand(probe.getName());
            commands.put(probe.getName(), command);
            Bukkit.getCommandMap().register("playtest", command);
            ((CraftServer) Bukkit.getServer()).syncCommands();
        }
        command.answers.put(player.getUniqueId(), new SuggestingCommand.Answer(List.copyOf(probe.getSuggestions()), probe.getAnswer()));
        player.updateCommands();
        return null;
    }

    @EventHandler(ignoreCancelled = true)
    public void onBreak(BlockBreakEvent event) {
        if (unbreakable.contains(event.getBlock().getLocation())) event.setCancelled(true);
    }

    @EventHandler
    public void onHit(EntityDamageByEntityEvent event) {
        Reactions reactions = spawned.get(event.getEntity().getUniqueId());
        if (reactions != null && reactions.onHit() != null && event.getDamager() instanceof Player) name(event.getEntity(), reactions.onHit());
    }

    @EventHandler
    public void onUse(PlayerInteractEntityEvent event) {
        Reactions reactions = spawned.get(event.getRightClicked().getUniqueId());
        if (reactions != null && reactions.onClick() != null) name(event.getRightClicked(), reactions.onClick());
    }

    @EventHandler
    public void onUseUnknown(PlayerUseUnknownEntityEvent event) {
        PacketEntity entity = packetEntities.get(event.getEntityId());
        if (entity == null || !entity.viewer().equals(event.getPlayer().getUniqueId())) return;
        String name = event.isAttack() ? entity.reactions().onHit() : entity.reactions().onClick();
        if (name == null) return;
        // The client knows this entity from packets alone, so its name tag changes by packet too.
        var detached = entity.detached();
        detached.setCustomName(PaperAdventure.asVanilla(Component.text(name)));
        detached.setCustomNameVisible(true);
        var changed = detached.getEntityData().packDirty();
        if (changed != null) send(event.getPlayer(), new ClientboundSetEntityDataPacket(detached.getId(), changed));
    }

    private static void name(Entity entity, String name) {
        entity.customName(Component.text(name));
        entity.setCustomNameVisible(true);
    }

    private static void send(Player player, net.minecraft.network.protocol.Packet<?> packet) {
        ((CraftPlayer) player).getHandle().connection.send(packet);
    }

    private static Location location(World world, BlockPos at) {
        return new Location(world, at.getX(), at.getY(), at.getZ());
    }

    /**
     * A command probes made: exists only for the players a probe gave it to, and for each suggests what
     * that probe named and answers with what was typed. Suggestions run on Paper's own threads.
     */
    private static final class SuggestingCommand extends Command {
        record Answer(List<String> suggestions, String answer) {}

        final Map<UUID, Answer> answers = new ConcurrentHashMap<>();

        SuggestingCommand(String name) {
            super(name);
        }

        @Override
        public boolean testPermissionSilent(CommandSender sender) {
            return sender instanceof Player player && answers.containsKey(player.getUniqueId());
        }

        @Override
        public boolean execute(CommandSender sender, String label, String[] args) {
            Answer answer = sender instanceof Player player ? answers.get(player.getUniqueId()) : null;
            if (answer != null) sender.sendMessage(Component.text(answer.answer() + " " + String.join(" ", args)));
            return true;
        }

        @Override
        public List<String> tabComplete(CommandSender sender, String alias, String[] args) {
            Answer answer = sender instanceof Player player ? answers.get(player.getUniqueId()) : null;
            if (answer == null) return List.of();
            String typed = args.length == 0 ? "" : args[args.length - 1];
            return answer.suggestions().stream().filter(it -> it.startsWith(typed)).toList();
        }
    }
}
