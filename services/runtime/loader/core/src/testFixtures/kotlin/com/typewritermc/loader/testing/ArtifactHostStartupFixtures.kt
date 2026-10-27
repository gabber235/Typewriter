package com.typewritermc.loader.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.LoaderService
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.flow.MutableStateFlow
import java.nio.file.Files
import java.nio.file.Path
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

fun startupEngineManifest(id: String): EngineManifest =
    EngineManifest(
        id = ArtifactId(id),
        version = ArtifactVersion("1.0.0"),
        hostApi = VersionConstraint("^1"),
        runtimeEntrypointClass = "fixture.Runtime",
        directCapabilities = emptyList(),
        resolvedCapabilities = emptyList(),
        bundledComponents = emptyList(),
        contributions = emptyList(),
    )

fun writeStartupJar(
    path: Path,
    manifest: ImprintManifest,
    content: String,
) {
    Files.createDirectories(path.parent)
    ZipOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
        archive.write(ImprintManifestCodec.encode(manifest))
        archive.closeEntry()
        archive.putNextEntry(ZipEntry("fixture.txt"))
        archive.write(content.encodeToByteArray())
        archive.closeEntry()
    }
}

class StartupLoaderService(
    root: Path,
) : LoaderService {
    override val artifactBlobs = FileDigestBlobStore(root)
    override val states = MutableStateFlow(RegistrarSnapshot(0, 0, RegistrarState.Idle))
    override val openTelemetry = OpenTelemetry.noop()
    override val telemetry = openTelemetry.serviceTelemetry("host-startup-test")

    override suspend fun start(): Nothing = error("The bootstrap owns service startup.")

    override suspend fun communicatorFor(connectionGeneration: Long): Nothing = error("No messaging session is needed.")

    override suspend fun rotateAuthorization(): Nothing = error("No assignment is applied.")

    override suspend fun releaseAuthorizationRotation(connectionGeneration: Long): Nothing = error("No authorization was rotated.")

    override fun sharedArtifacts(realmId: String): Nothing = error("No runtime is assigned.")

    override suspend fun stop(): RegistrarStopResult = RegistrarStopResult.Success
}
