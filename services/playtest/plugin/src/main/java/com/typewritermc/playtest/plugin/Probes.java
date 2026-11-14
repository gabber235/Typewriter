package com.typewritermc.playtest.plugin;

import com.destroystokyo.paper.event.player.PlayerUseUnknownEntityEvent;
import com.typewritermc.playtest.wire.Message.BlockPos;
import com.typewritermc.playtest.wire.Message.Kind;
import com.typewritermc.playtest.wire.Message.PlayerAction;
import com.typewritermc.playtest.wire.Message.ProbeAction;
import com.typewritermc.playtest.wire.Message.ProbeCancelBreaking;
import com.typewritermc.playtest.wire.Message.ProbeChat;
import com.typewritermc.playtest.wire.Message.ProbeCommand;
import com.typewritermc.playtest.wire.Message.ProbeFill;
import com.typewritermc.playtest.wire.Message.ProbeGameMode;
import com.typewritermc.playtest.wire.Message.ProbeGive;
import com.typewritermc.playtest.wire.Message.ProbeMark;
import com.typewritermc.playtest.wire.Message.ProbePacketEntity;
import com.typewritermc.playtest.wire.Message.ProbeSelectSlot;
import com.typewritermc.playtest.wire.Message.ProbeSpawn;
import com.typewritermc.playtest.wire.Message.ProbeTeleport;
import com.typewritermc.playtest.wire.Message.ProbeWork;
import com.typewritermc.playtest.wire.Message.WorldAction;
import io.papermc.paper.adventure.PaperAdventure;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.BiConsumer;
import net.kyori.adventure.text.Component;
import net.minecraft.core.registries.BuiltInRegistries;
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
import org.bukkit.util.Vector;
import org.jspecify.annotations.Nullable;

/**
 * The arrangements a requirement asks Paper for. Main thread only. Each runs at once and returns null,
 * or returns why it could not. What a probe gives a player (a command, an entity only its client knows)
 * is that player's alone, and a claim takes it away again; what it places in the world stays in the
 * attempt's region, which no later attempt uses.
 */
final class Probes implements Listener {
    private static final int MAX_FILL = 4_096;

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
    private final BiConsumer<Player, Kind> mark;

    /** [mark] leaves a mark of a kind of state on a player, for the framework's own test kit. */
    Probes(Plugin plugin, BiConsumer<Player, Kind> mark) {
        this.plugin = plugin;
        this.mark = mark;
    }

    /**
     * Runs [action]: an action on a player for each of [players], an action on the world once, in their
     * world. Null when it ran, else why not.
     */
    @Nullable String run(List<Player> players, ProbeAction action) {
        return switch (action) {
            case WorldAction world -> run(players.getFirst().getWorld(), world);
            case PlayerAction each -> {
                for (Player player : players) {
                    String failure = run(player, each);
                    if (failure != null) yield failure;
                }
                yield null;
            }
        };
    }

    private @Nullable String run(World world, WorldAction action) {
        return switch (action) {
            case ProbeFill fill -> fill(world, fill);
            case ProbeSpawn spawn -> spawn(world, spawn);
            case ProbeCancelBreaking cancel -> {
                unbreakable.add(location(world, cancel.at()));
                yield null;
            }
        };
    }

    private @Nullable String run(Player player, PlayerAction action) {
        return switch (action) {
            case ProbeChat chat -> {
                player.sendMessage(Component.text(chat.text()));
                yield null;
            }
            case ProbeGameMode mode -> gameMode(player, mode.mode());
            case ProbeTeleport teleport -> {
                player.setVelocity(new Vector());
                player.setFallDistance(0);
                player.teleport(new Location(player.getWorld(), teleport.x(), teleport.y(), teleport.z(), teleport.yaw(), teleport.pitch()));
                yield null;
            }
            case ProbeGive give -> give(player, give);
            case ProbeSelectSlot select -> {
                if (select.slot() < 0 || select.slot() > 8) yield "hotbar slot " + select.slot() + " is not 0 to 8";
                player.getInventory().setHeldItemSlot(select.slot());
                yield null;
            }
            case ProbePacketEntity entity -> packetEntity(player, entity);
            case ProbeCommand command -> command(player, command);
            case ProbeMark marked -> {
                mark.accept(player, marked.kind());
                yield null;
            }
            case ProbeWork work -> {
                work(player, work);
                yield null;
            }
        };
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
    private void work(Player player, ProbeWork work) {
        Bukkit.getScheduler().runTaskAsynchronously(plugin, PlayerWork.task(player, work.name(), () -> {
            try {
                Thread.sleep(work.millis());
            } catch (InterruptedException cancelled) {
                Thread.currentThread().interrupt();
                return;
            }
            player.sendMessage(Component.text(work.chat()));
        }));
    }

    private static @Nullable String gameMode(Player player, String mode) {
        try {
            player.setGameMode(GameMode.valueOf(mode.toUpperCase(Locale.ROOT)));
            return null;
        } catch (IllegalArgumentException unknown) {
            return "game mode " + mode + " is not survival, creative, adventure or spectator";
        }
    }

    private static @Nullable String give(Player player, ProbeGive give) {
        Material material = Material.matchMaterial(give.item());
        if (material == null || !material.isItem()) return "no item " + give.item();
        if (give.slot() < 0 || give.slot() > 40) return "inventory slot " + give.slot() + " is not 0 to 40";
        player.getInventory().setItem(give.slot(), material.isAir() ? null : new ItemStack(material, give.count()));
        return null;
    }

    private static @Nullable String fill(World world, ProbeFill fill) {
        BlockData data;
        try {
            data = Bukkit.createBlockData(fill.block());
        } catch (IllegalArgumentException unknown) {
            return "no block state " + fill.block();
        }
        BlockPos from = fill.from();
        BlockPos to = fill.to();
        long count = (long) (Math.abs(to.x() - from.x()) + 1) * (Math.abs(to.y() - from.y()) + 1) * (Math.abs(to.z() - from.z()) + 1);
        if (count > MAX_FILL) return "a fill of " + count + " blocks is over the limit of " + MAX_FILL;
        for (int x = Math.min(from.x(), to.x()); x <= Math.max(from.x(), to.x()); x++) {
            for (int y = Math.min(from.y(), to.y()); y <= Math.max(from.y(), to.y()); y++) {
                for (int z = Math.min(from.z(), to.z()); z <= Math.max(from.z(), to.z()); z++) {
                    world.getBlockAt(x, y, z).setBlockData(data, false);
                }
            }
        }
        return null;
    }

    private @Nullable String spawn(World world, ProbeSpawn spawn) {
        EntityType type = Registry.ENTITY_TYPE.get(NamespacedKey.fromString(spawn.type()));
        if (type == null || !type.isSpawnable() || type.getEntityClass() == null) return "no entity type " + spawn.type();
        var at = new Location(world, spawn.x(), spawn.y(), spawn.z(), spawn.yaw(), 0);
        world.spawn(at, type.getEntityClass(), entity -> {
            ((CraftEntity) entity).getHandle().setUUID(spawn.uuid());
            entity.setSilent(true);
            entity.setPersistent(true);
            if (entity instanceof LivingEntity living) {
                living.setAI(false);
                living.setRemoveWhenFarAway(false);
            }
        });
        spawned.put(spawn.uuid(), new Reactions(spawn.onHit(), spawn.onClick()));
        return null;
    }

    private @Nullable String packetEntity(Player viewer, ProbePacketEntity spawn) {
        var key = Identifier.tryParse(spawn.type());
        var type = key == null ? null : BuiltInRegistries.ENTITY_TYPE.getOptional(key).orElse(null);
        if (type == null) return "no entity type " + spawn.type();
        var detached = type.create(((CraftWorld) viewer.getWorld()).getHandle(), EntitySpawnReason.COMMAND);
        if (detached == null) return "entity type " + spawn.type() + " cannot be created";
        int id = detached.getId();
        send(viewer, new ClientboundAddEntityPacket(id, spawn.uuid(), spawn.x(), spawn.y(), spawn.z(), 0, spawn.yaw(), type, 0, Vec3.ZERO, spawn.yaw()));
        packetEntities.put(id, new PacketEntity(viewer.getUniqueId(), detached, new Reactions(spawn.onHit(), spawn.onClick())));
        return null;
    }

    /** [player] may run `/name`, which suggests and answers as [probe] says, for it alone. */
    private @Nullable String command(Player player, ProbeCommand probe) {
        SuggestingCommand command = commands.get(probe.name());
        if (command == null) {
            command = new SuggestingCommand(probe.name());
            commands.put(probe.name(), command);
            Bukkit.getCommandMap().register("playtest", command);
            ((CraftServer) Bukkit.getServer()).syncCommands();
        }
        command.answers.put(player.getUniqueId(), new SuggestingCommand.Answer(List.copyOf(probe.suggestions()), probe.answer()));
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
        return new Location(world, at.x(), at.y(), at.z());
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
