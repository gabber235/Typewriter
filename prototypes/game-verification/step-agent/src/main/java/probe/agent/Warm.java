package probe.agent;

import net.minecraft.commands.Commands;
import net.minecraft.server.WorldLoader;
import net.minecraft.server.packs.repository.PackRepository;
import net.minecraft.server.packs.repository.ServerPacksSource;
import net.minecraft.server.permissions.LevelBasedPermissionSet;
import net.minecraft.util.Util;
import net.minecraft.world.level.WorldDataConfiguration;

/**
 * Restore prototype: one throwaway load of the vanilla data packs before the checkpoint, from the jar only (no server
 * folder, no level.dat), so the classes and compiled code of the real load after the restore are warm. The result is
 * closed and dropped.
 */
final class Warm {
    private Warm() {}

    static void datapacks() throws Exception {
        PackRepository repo = ServerPacksSource.createVanillaTrustedRepository();
        WorldLoader.InitConfig init = new WorldLoader.InitConfig(new WorldLoader.PackConfig(repo, WorldDataConfiguration.DEFAULT, false, true),
                Commands.CommandSelection.DEDICATED, LevelBasedPermissionSet.GAMEMASTER);
        WorldLoader.<Void, Void>load(init, ctx -> new WorldLoader.DataLoadOutput<>(null, ctx.datapackDimensions()),
                (closeable, resources, registries, cookie) -> {
                    closeable.close();
                    return null;
                }, Util.backgroundExecutor(), Runnable::run).get();
    }
}
