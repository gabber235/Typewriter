# Runtime development

The services composite exposes one entrypoint for each local runtime workflow.

## Standalone host

Run `build-logic/gradlew devStandalone` from `services`. The task builds the combined loader and starts a local host in `services/build/development/standalone`. Stop it with Control C. The local bootstrap intentionally has no child runtime until a deployment source is configured.

## Paper host

Run `build-logic/gradlew devPaper` from `services`. The task builds the same combined loader first, then starts a disposable Paper 1.21.11 server in `services/dev-paper/build/server` using `xyz.jpenilla.run-paper` 3.0.2.

The requested plugin version 3.1.0 is not compatible with this repository's Gradle 9.6.1 runtime because its plugin classpath fails while loading Kotlin serialization. Version 3.0.2 provides the required disposable server workflow and was verified with the combined loader.

## Development artifacts

Run `build-logic/gradlew publishDevArtifacts` from `services`. The task builds the Realm, panel engine, execution engines, engine capabilities, and ConformanceExtension. It publishes Realm import filenames into `services/build/development/artifacts`.

Point a development Realm importer at that directory. Rebuilding an artifact replaces only the mutable import file. Realm imports its bytes under a new immutable file revision.

## Verification

Run `build-logic/gradlew check` from `services` for the complete services composite. Run `build-logic/gradlew :loader:check` only from a build that includes the loader under that path. The loader build itself uses `../build-logic/gradlew check` from `services/loader`.

## Live acceptance record

Record the repository commit, artifact revisions, cluster publication command, affected workload replica sets, topology configurations, hot replacement result, rollback result, and offline restoration result for each manual acceptance run. Do not record a scenario as passing unless the actual runtime path was exercised.

### 2026 08 20 scaffold acceptance

The source revision included all scaffold commits through `929206ad`. The workflow changes and this record belong to the following phase commit.

Local runtime results:

1. `build-logic/gradlew publishDevArtifacts` published eight version 1.0.0 import files for Realm, panel, Paper, conformance, Minecraft, both fixture capabilities, and ConformanceExtension.
2. `build-logic/gradlew devStandalone` started the combined loader with host identity `local-standalone`. It created persistent state in `services/build/development/standalone` and remained active until interrupted with Control C.
3. `build-logic/gradlew devPaper` started Paper 1.21.11 build 132. Paper loaded and enabled `TypewriterLoader`, reached its ready state, then disabled the loader and stopped cleanly through the server console.

Cluster publication results:

1. The planned `dagger call wash publish` command is not present in the current Dagger API. The current equivalent is `dagger call wash publish-components`.
2. Service registration was published as `oci.local.seamlezz.net/typewriter/service-registration:latest`. Only `service-registration-5796764c99` was removed. Its replacement, `service-registration-55769cc897`, became ready.
3. Authorization permissions were published as `oci.local.seamlezz.net/typewriter/auth-typewriter-permissions:latest`. Only `auth-auth-typewriter-permissions-6d65f4796` was removed. Its replacement, `auth-auth-typewriter-permissions-d6769c8df`, became ready.
4. No SurrealDB records were cleared.

Built in browser results:

1. The real panel opened at `http://localhost:2350`, authenticated with the existing browser session, opened organization `5hiymtu2zzhxprsdi1f8`, and requested both service and topology watches.
2. The first topology watch timed out because the panel credential lacked the topology subjects. The authorization contract now grants topology watch publication, topology event subscription, and topology configuration publication. Its focused component test passed with one test and zero failures.
3. After the authorization workload restart, the browser session was signed out to request fresh messaging credentials. The local authentication callback remained indefinitely in its loading state on two attempts. This prevented a second authenticated topology watch during this run.
4. The browser also exposed an existing `ShimmerLoading` layout assertion while the service skeleton was active. It is unrelated to the runtime scaffold and was not changed in this phase.

The distributed scenarios are not marked as passing. The current loader has a tested local bootstrap and fake control plane, but it does not yet provide a production messaging control plane adapter or backend service registration adapter. Consequently, this run could not register standalone and Paper hosts in the live backend, configure combined or distributed execution through the panel, observe local and remote artifact resolution through live hosts, or exercise hot replacement, rollback, and offline restoration against the cluster. Focused loader, Realm, file transfer, lifecycle, rollback, and offline restoration tests cover those scaffold contracts until those adapters are implemented.
